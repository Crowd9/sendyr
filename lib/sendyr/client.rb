require 'uri'

module Sendyr
	class Client
		attr_reader :http_client, :last_result, :api_key, :base_uri, :list_id

		def initialize(list_id = nil)
			@list_id     = list_id
			@api_key     = Sendyr.configuration.api_key
			@base_uri    = Sendyr.configuration.url
		end

		def subscribe(opts = {})
			opts = {boolean: true, list: @list_id}.merge(opts)
			raise_if_missing_arg([:email, :list], opts)

			path   = '/subscribe'
			result = post_to(path, opts)

			if result.success? && %w(true).include?(clean_body(result))
				respond_with_success(result)
			else
				respond_with_failure(result)
			end
		end

		def unsubscribe(opts = {})
			opts = {boolean: true, list: @list_id}.merge(opts)
			raise_if_missing_arg([:email, :list], opts)

			path   = '/unsubscribe'
			result = post_to(path, opts)

			if result.success? && %w(true).include?(clean_body(result))
				respond_with_success(result)
			else
				respond_with_failure(result)
			end
		end

		def subscription_status(opts = {})
			opts = {api_key: @api_key, list_id: @list_id}.merge(opts)
			raise_if_missing_arg([:api_key, :email, :list_id, :api_key], opts)

			path   = '/api/subscribers/subscription-status.php'
			result = post_to(path, opts)

			success_messages = { "subscribed"   => :subscribed,
													 "unsubscribed" => :unsubscribed,
													 "unconfirmed"  => :unconfirmed,
													 "bounced"      => :bounced,
													 "soft bounced" => :soft_bounced,
													 "complained"   => :complained,
													 "email does not exist in list" => :not_in_list }

      cleaned_body = clean_body(result)
			if result.success? && success_messages.keys.include?(cleaned_body)
				respond_with_success(result, success_messages[cleaned_body])
			else
				respond_with_failure(result, underscore(cleaned_body).to_sym)
			end
		end

		def active_subscriber_count(opts = {})
			opts = {api_key: @api_key, list_id: @list_id}.merge(opts)
			raise_if_missing_arg([:list_id, :api_key], opts)

			path   = '/api/subscribers/active-subscriber-count.php'
			result = post_to(path, opts)

			cleaned_body = clean_body(result)
			if result.success? && !!(cleaned_body =~ /^[-+]?[0-9]+$/)
				respond_with_success(result, cleaned_body.to_i)
			else
				respond_with_failure(result)
			end
		end

	private
		def raise_if_missing_arg(mandatory_fields, opts)
			mandatory_fields.each do |key|
				if opts[key].nil? || opts[key].to_s.strip == ''
					raise ArgumentError.new("You must specify :#{key}.")
				end
			end; nil
		end

		def post_to(path, params)
			Faraday.post(url_for(path), params)
		end

		def url_for(path)
			URI.join(@base_uri, path).to_s
		end

		def clean_body(result)
			result.body.strip.chomp.downcase
		end

		def respond_with_success(result, value = nil)
			@last_result = result
			value.nil? ? true : value
		end

		def respond_with_failure(result, value = nil)
			@last_result = result
			value.nil? ? false : value
		end

		def underscore(word)
		  word = word.to_s.dup
		  word.gsub!(/::/, '/')
		  word.gsub!(/(?:([A-Za-z\d])|^)(#{inflections.acronym_regex})(?=\b|[^a-z])/) { "#{$1}#{$1 && '_'}#{$2.downcase}" }
		  word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
		  word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
		  word.tr!("-", "_")
		  word.downcase!
		  word
		end
	end
end