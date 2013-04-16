class Shortener::ShortenedUrlsController < ActionController::Base

  # find the real link for the shortened link key and redirect
  def show
    # only use the leading valid characters
    token = /^([#{Shortener.key_chars.join}]*).*/.match(params[:id])[1]

    # pull the link out of the db
    sl = ::Shortener::ShortenedUrl.find_by_unique_key!(token)

    token = "#{rand(1000000)}-#{sl.unique_key}"
    cookies.signed[:linktoken] = {
      :value => sl.id,
      :expires => 1.year.from_now
    }
    cookies.signed[:clicktoken] = {
      :value => token,
      :expires => 1.year.from_now
    }

    if sl
      # don't want to wait for the increment to happen, make it snappy!
      # this is the place to enhance the metrics captured
      # for the system. You could log the request origin
      # browser type, ip address etc.
      Thread.new do
        sl.increment!(:use_count)
        click = ::Shortener::ShortenedClick.new
        click.shortened_url_id = sl.id
        click.agent = request.user_agent
        click.token = token
        click.referer = request.env["HTTP_REFERER"]
        click.ip = request.ip
        click.remote_ip = request.remote_ip
        click.save

        ActiveRecord::Base.connection.close
      end
      # do a 301 redirect to the destination url
      if sl.hat?
        redirect_to sl.url, :status => :moved_permanently
      else
        redirect_to "http://social.shoelovin.com/links/#{sl.unique_key}/share", :status => :moved_permanently
      end
    end
  end

end
