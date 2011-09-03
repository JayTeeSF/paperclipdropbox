require "yaml"
require "dropbox"

namespace :paperclipdropbox do


	desc "Create DropBox Authorized Session Yaml"
	task :authorize => :environment do

		SESSION_FILE = "#{Rails.root}/config/dropboxsession.yml"

    unless @dropboxsession = Paperclip::Storage::Dropboxstorage.dropbox_session
			@options = (YAML.load_file("#{Rails.root}/config/paperclipdropbox.yml")[Rails.env].symbolize_keys)

			@dropbox_user = @options[:dropbox_user]
			@dropbox_password = @options[:dropbox_password]
      @dropbox_key = @options[:dropbox_key]
      raise "Missing dropbox_key" unless @dropbox_key
      @dropbox_secret = @options[:dropbox_secret]
      raise "Missing dropbox_secret" unless @dropbox_secret

			@dropboxsession = Dropbox::Session.new(@dropbox_key, @dropbox_secret)
			@dropboxsession.mode = :dropbox

      puts "Visit #{@dropboxsession.authorize_url} to log in to Dropbox. Hit enter when you have done this."

      $stdin.flush

      STDIN.gets

		end
		puts ""
		puts ""
		puts ""
		begin
			@dropboxsession.authorize

			puts "Authorized - #{@dropboxsession.authorized?}"
		rescue
			begin
				puts "Please login to dropbox using this link : #{@dropboxsession.authorize_url}"
				puts "then run this rake task again."
			rescue
				puts "Already Authorized - #{@dropboxsession.authorized?}"
			end
		end

		puts ""
		puts ""
		File.open(SESSION_FILE, "w") do |f|
			f.puts @dropboxsession.serialize
		end
	end

end
