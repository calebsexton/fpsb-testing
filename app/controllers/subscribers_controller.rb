class SubscribersController < StatusBoardWidgets
  set :views, "app/views/subscribers"

  # Subscriber graph with URI.LV
  get '/graph' do
    type = params[:type] || "line"
    feed_params = feed_params(params)
    graph = create_graph(feed_params, type, params[:api_key], params[:token])  
    json graph
  end
  
  # Subscriber table with URI.LV
  get '/table' do
    @uri = "/subscribers/count?" + URI.encode_www_form(params)
    erb :index
  end

  # Subscriber count with URI.LV
  get '/count' do
    feed_params = feed_params(params)
    @feeds = create_counts(feed_params, params[:api_key], params[:token])
    erb :count
  end

  private

  def feed_params(params)
    params.select { |k, v| k.include?("feed") }
  end

  def create_graph(feed_params, type, api_key, token)
    graph = {
      graph: {
        title: 'Subscribers',
        type: type,
        refreshEveryNSeconds: 3600,
        datasequences: []
      }
    }
  
    feed_params.each do |key, feed, color|
      stats = fetch_subscribers(api_key, token, feed, true)
      
      if feed_params.size == 1
        graph[:graph][:title] = feed.gsub('-', ' ')

        graph[:graph][:datasequences] << { title: "Google Reader",
                                           datapoints: create_datapoints(stats, 'greader') }
        graph[:graph][:datasequences] << { title: "Other",
                                           datapoints: create_datapoints(stats, 'other') }
        graph[:graph][:datasequences] << { title: "Direct",
                                           datapoints: create_datapoints(stats, 'direct') }
      else
        graph[:graph][:datasequences] << { title: feed.gsub('-', ' '),
                                           datapoints: create_datapoints(stats, 'greader') }
      end
    end
    graph
  end

  def create_counts(feed_params, api_key, token)
    counts = []
      feed_params.each do |key, feed, color|
      stats = fetch_subscribers(params[:api_key], params[:token], feed, color)
      counts << {
        name: feed.gsub('-', ' '),
        count: stats['greader']
      }
    end
    counts = counts.sort_by { |k| k[:count] }.reverse
  end

  def fetch_subscribers(key, token, feed, color, history=false)
    uri = URI.parse("http://api.uri.lv/feeds/subscribers.json")
      parameters = { :key => key, :token => token, :feed => feed :color => color}
    uri.query = URI.encode_www_form(parameters)
    if history
      MultiJson.load(uri.open.read)["stats"].reverse
    else
      MultiJson.load(uri.open.read)["stats"].first
    end
  end

  def create_datapoints(stats, type)
    datapoints = []
    stats.each do |entry|
      datapoints << {
        title: Time.at(entry["day"]).strftime("%-m.%e"),
        value: entry['greader']
      }
    end
    datapoints
  end
end
