module Sidekiq
  module Errors
    module WebExtension
      def self.registered(app)
        view_path = File.join(File.expand_path("..", __FILE__), "views")

        app.post "/errors/:error_class/:error_message/retry" do
          @error_class = params[:error_class]
          @error_message = params[:error_message]
          Sidekiq::RetrySet.new.select do |retri|
            retri.item['error_class'] == @error_class &&
            Digest::MD5.hexdigest(retri.item['error_message']) == @error_message
          end.map(&:retry).length
          redirect "#{root_path}errors/#{@error_class}/#{@error_message}"
        end

        app.post "/errors/:error_class/:error_message/delete" do
          @error_class = params[:error_class]
          @error_message = params[:error_message]
          Sidekiq::RetrySet.new.select do |retri|
            retri.item['error_class'] == @error_class &&
            Digest::MD5.hexdigest(retri.item['error_message']) == @error_message
          end.map(&:delete).length
          redirect "#{root_path}errors/#{@error_class}/#{@error_message}"
        end
              
        app.post "/errors/:error_class/retry" do
          @error_class = params[:error_class]
          Sidekiq::RetrySet.new.select do |retri|
            retri.item['error_class'] == @error_class
          end.map(&:retry).length
          redirect "#{root_path}errors/#{@error_class}"
        end

        app.post "/errors/:error_class/delete" do
          @error_class = params[:error_class]
          Sidekiq::RetrySet.new.select do |retri|
            retri.item['error_class'] == @error_class
          end.map(&:delete).length
          redirect "#{root_path}errors/#{@error_class}"
        end

        app.get "/errors/:error_class/:error_message" do
          @error_class = params[:error_class]
          @error_message = params[:error_message]
          @retries = Sidekiq.redis {|c| c.zrange("retry", 0, Sidekiq.errors_max_count, :with_scores => true) }
          @retries = @retries
            .map {|msg, score| Sidekiq::SortedEntry.new(nil, score, msg) }
            .select{|job| job['error_class'] == @error_class }
            .select{|job| Digest::MD5.hexdigest(job['error_message']) == @error_message }
          @total_size = @count = @retries.length
          render(:erb, File.read(File.join(view_path, "errors_class_message.erb")))
        end
      
        app.get "/errors/:error_class" do
          @error_class = params[:error_class]
          @error_messages = Hash[
            Hash[
              *Sidekiq.redis {|c| c.zrange("retry", 0, Sidekiq.errors_max_count) }
              .collect{|job| Sidekiq.load_json(job)}
              .select{|job| job['error_class'] == @error_class }
              .collect{|job| job['error_message'] }
              .group_by{ |v| v }.flat_map{ |k, v| [k, v.size] }
            ]
            .sort_by{|k,v| v}
            .reverse
          ]
          render(:erb, File.read(File.join(view_path, "errors_class.erb")))
        end
      
        app.get "/errors" do
          @errors = Hash[
            Hash[
              *Sidekiq.redis {|c| c.zrange("retry", 0, Sidekiq.errors_max_count) }
              .collect{|job| Sidekiq.load_json(job)['error_class']}
              .group_by{ |v| v }.flat_map{ |k, v| [k, v.size] }
            ]
            .sort_by{|k,v| v}
            .reverse
          ]
          render(:erb, File.read(File.join(view_path, "errors.erb")))
        end
        
      end
    end
  end
end
