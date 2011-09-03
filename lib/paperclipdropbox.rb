module Paperclipdropbox
  require 'paperclipdropbox/railtie' if defined?(Rails)
end

module Paperclip
	module Storage
		module Dropboxstorage
			extend self

			def self.extended(base)
				require "dropbox"
				base.instance_eval do

					if File.exists?("#{Rails.root}/config/paperclipdropbox.yml")
						@options.merge!(YAML.load_file("#{Rails.root}/config/paperclipdropbox.yml")[Rails.env].symbolize_keys)
					end

					@dropbox_user = @options[:dropbox_user]
					@dropbox_password = @options[:dropbox_password]
					@dropbox_key = options[:dropbox_key]
					raise "Missing dropbox_key" unless @dropbox_key
					@dropbox_secret = options[:dropbox_secret]
					raise "Missing dropbox_secret" unless @dropbox_secret
					@dropbox_public_url = @options[:dropbox_public_url] || "http://dl.dropbox.com/u/"
					@options.merge!( :url => "#{@dropbox_public_url}#{user_id}#{@options[:path]}" )
					@url = @options[:url]
					@path = @options[:path]
					log("Starting up DropBox Storage")
				end
			end

			def exists?(style = default_style)
				log("exists?  #{style}")
				begin
					dropbox_session.metadata("/Public#{File.dirname(path(style))}")
					log("true")
					true
				rescue
					log("false")
					false
				end
			end

			def to_file(style=default_style)
				log("to_file  #{style}")
				return @queued_for_write[style] || "#{@dropbox_public_url}#{user_id}/#{path(style)}"
			end

			def flush_writes #:nodoc:
				log("[paperclip] Writing files #{@queued_for_write.count}")
				@queued_for_write.each do |style, file|
					log("[paperclip] Writing files for ")
					file.close
					dropbox_session.upload(file.path, "/Public#{File.dirname(path(style))}", :as=> File.basename(path(style)))
				end
				@queued_for_write = {}
			end

			def flush_deletes #:nodoc:
				@queued_for_delete.each do |path|
					log("[paperclip] Deleting files for #{path}")
					begin
						dropbox_session.rm("/Public/#{path}")
					rescue
					end
				end
				@queued_for_delete = []
			end

			def user_id
				unless Rails.cache.exist?('DropboxSession:uid')
					log("get Dropbox Session User_id")
					Rails.cache.write('DropboxSession:uid', dropbox_session.account.uid)
					dropbox_session.account.uid
				else
					log("read Dropbox User_id")
					Rails.cache.read('DropboxSession:uid')
				end
			end

			def dropbox_session
				unless Rails.cache.exist?('DropboxSession')
					if @dropboxsession.blank?
						log("loading session from yaml") if respond_to?(:log)
						if File.exists?("#{Rails.root}/config/dropboxsession.yml")
							@dropboxsession = Dropbox::Session.deserialize(File.read("#{Rails.root}/config/dropboxsession.yml"))
              @dropboxsession.mode = :dropbox
						end
          else
            @dropboxsession.mode = :dropbox
					end
					@dropboxsession
				else
					log("reading Dropbox Session") if respond_to?(:log)
					Rails.cache.read('DropboxSession')
				end
			end
		end
	end
end
