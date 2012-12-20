require 'flacinfo'
require 'taglib'
require 'json'
require 'digest/sha2'

module Radiop
  class Track
    def self.from_file(filename,stat=nil)
      if (extn=File::extname(filename).slice(1..-1)) && 
          !IGNORE_FILES.member?(extn.downcase) &&
          extn.match(/\A[a-z]/i) 
        extn = extn.gsub(/\W/,'').capitalize
        if Track.const_defined?(extn) and
            clss=Track.const_get(extn) and
            clss.is_a?(Class)
          clss.new(filename,stat)
        end
      end
    end
    
    def initialize(filename,stat)
      @filename = filename
      if stat
        @stat=stat
      end
    end
    def key
      @key ||= Digest.hexencode(Digest::SHA256.new.tap {|d|
                                  d.update(File.read(@filename)) 
                                }.digest)
    end
    def stat
      @stat ||= File.stat(@filename)
    end
    
    def stringize_keys(h)
      Hash[h.map {|k,v| [k.to_s, v] }]
    end
    def attributes
      t=begin
          tags
        rescue BadFileError
          warn "can't read tags in #{@filename}"
          {}
        end
      t and stringize_keys({ location: @filename,
                             bytes: self.stat.size,
                             inode: self.stat.ino
                           }.merge(t))
    end
    class Flac < Track
      def tags
        begin
          flac=FlacInfo.new(@filename)
        rescue FlacInfoReadError
          raise BadFileError
        end
        comment = flac.comment.map {|s|
          u=s.dup
          u.force_encoding('UTF-8')
          u.valid_encoding? ? u : s
        }
        h=Hash[comment.map {|field| 
                 k,v=field.split('=')
                 [k,v]
               }]
        {
          creator: h['ARTIST'],
          album: h['ALBUM'],
          title: h['TITLE'],
          ext_year: h['DATE'],
          trackNum: h['TRACKNUMBER'],
          ext_flac_comment: comment.to_json
        }
      end
    end
    class Mp3 < Track
      def tags
        begin
          TagLib::MPEG::File.open(@filename) do |file|
            tag = file.tag
            {
              creator: tag.artist,
              album: tag.album,
              title: tag.title,
              ext_year: tag.year,
              trackNum: tag.track,
              ext_id3v2_frames: file.id3v2_tag.frame_list.map {|frame| 
                [frame.frame_id,frame.to_string]
              }.to_json
            }
          end
        rescue FlacInfoReadError
          raise BadFileError
        end
      end
    end
  end
end
