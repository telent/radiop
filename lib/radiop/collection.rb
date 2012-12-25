require 'find'
require 'tokyocabinet'

class Radiop::Collection
  IGNORE_FILES=%w(mood m3u)
  attr_reader :duplicates, :empties, :directory
  def initialize(args)
    @directory=args[:directory] or raise "Required argument :directory missing"
    @database_name=args[:database_name] || File.join(@directory,"radiatorbase.tdb")
    @db = TokyoCabinet::TDB.new
    @last_updated_at = 
      begin
        File.stat(@database_name).mtime
      rescue Errno::ENOENT
        Time.at(0)
      end
    @duplicates = Hash.new {|h,k| h[k]=Set.new }
    @empties = []
  end
  def with_database
    if @db.path
      return yield(@db)
    end
    begin
      @db.open(@database_name,
               TokyoCabinet::TDB::OWRITER | TokyoCabinet::TDB::OCREAT)
      yield(@db)
    ensure
      @db.close
    end
  end

  def update_file(filename)
    stat = File.stat(filename)
    return unless stat.file? 
    if stat.mtime < @last_updated_at
      # if we have changed the db format (e.g. to add new audio types
      # or to extract more info from old ones) this is a bad check and
      # there needs to be a way to force a rescan
      # warn "#{filename} older than last db update"
      # return
    end
    if stat.size.zero?
      # probably we should store empty files and duplicates so that
      # the user can take action on them e.g. by deleting them
      $stderr.print "E"
      @empties << filename
      return
    end
    if track=Track.from_file(filename,stat)
      with_database do |db|
        existing=db.get(track.key) 
        if existing && 
            (existing['location']==filename)
          warn "seen file #{filename}"
        elsif existing 
          $stderr.print "D"
          @duplicates[track.key] << existing['location']
          @duplicates[track.key] << filename
        else
          $stderr.print "."
           if tags=track.attributes
            db.put track.key, tags
          end
        end
      end
    else
      # should log these
      # should have a list of known non-audio formats (e.g. .mood, .txt)
      # that we can skip
      # warn "Can't recognise filename #{filename} as audio"
    end
  end

  def update
    with_database do |db|
      Find.find(@directory) do |f|
        self.update_file f
      end
    end
  end

  def search(attributes)
    with_database do |db|
      q = TokyoCabinet::TDBQRY::new(db)
      attributes.keys.each do |a|
        v=attributes[a]
        case k=a.to_s
        when 'artist','album','title' then
          q.addcond(k, TokyoCabinet::TDBQRY::QCSTRBW, v)
        when 'attributes' then
          q.addcond(k, TokyoCabinet::TDBQRY::QCSTRAND ,v)
        when 'year' then
          min,max = attributes[k].split /( +|\.\.|,|-)/
          if min && max
            q.addcond(a, TokyoCabinet::TDBQRY::QCNUMBT, [min,max].join(' '))
          elsif min
            q.addcond(a, TokyoCabinet::TDBQRY::QCNUMEQ, min)
          end
        end
        # qry.setorder("track_number", TokyoCabinet::TDBQRY::QOSTRDESC)
        # qry.setlimit(10)
        res = q.search
        ret = []
        res.each do |rkey|
          ret << db.get(rkey)
        end
        return ret
      end
    end
  end
end
