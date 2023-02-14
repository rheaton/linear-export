class LimitsManager
  attr_reader :last_complexity
  # stats is by token
  def initialize(key_list)
    @all_keys = key_list
    @stats = {}
  end

  def log_key_stats(selected_key)
    puts "Stats:"
    @stats.each do |key, stats|
      if selected_key == key
        print "> "
      else
        print "  "
      end
      puts "%.11s | Comp Rem: %10d | Comp Reset: %s | Req Rem: %10d | Req Reset: %s" % [
        key,
        stats[:complexity_remaining],
        stats[:complexity_reset].strftime('%m/%d %I:%M%p'),
        stats[:requests_remaining],
        stats[:requests_reset].strftime('%m/%d %I:%M%p')
      ]
    end
  end

  def refresh_stats
    @stats.delete_if do |_, value|
      value[:complexity_reset] < Time.now - 30
    end
  end

  def install_healthiest_key(fetcher)
    refresh_stats
    unused_key = @all_keys.find { |key| !@stats.key?(key) }
    unless unused_key.nil?
      puts "Swapping to unused or refreshed token: %.11s" % unused_key
      fetcher.update_token(unused_key)
      return unused_key
    end
    # if we get here, all keys have usage
    best_token = @all_keys.max_by {|key| @stats[key][:complexity_remaining] }
    puts "Swapping to healthiest token: %.11s" % best_token
    log_key_stats(best_token)
    fetcher.update_token(best_token)
    best_token
  end

  def block_until_safe(token, expected_complexity)
    return if @stats[token].nil?
    complexity_budget_ok = @stats[token][:complexity_remaining] > expected_complexity
    requests_available = @stats[token][:requests_remaining] > 1
    if complexity_budget_ok && requests_available
      puts "COMP: %10d - REQ: %10d" % [@stats[token][:complexity_remaining], @stats[token][:requests_remaining]]
      return
    end
    if !complexity_budget_ok && !requests_available
      wait_until = [@stats[token][:complexity_reset], @stats[token][:requests_reset]].max
    elsif !requests_available
      wait_until = @stats[token][:requests_reset]
    elsif !complexity_budget_ok
      wait_until = @stats[token][:complexity_reset]
    end
    seconds_to_wait = wait_until - Time.now
    puts 'For complexity %d, waiting until: %s which I think is %d seconds' % [expected_complexity, wait_until, seconds_to_wait.to_i]
    sleep(seconds_to_wait.to_i + 30)
  end

  def process(token, response_metadata)
    if response_metadata.nil?
      puts "OH NO"
    end
    @last_complexity = response_metadata.header['X-Complexity'].to_i
    complexity_reset = Time.mktime(2032)
    ratelimit_reset = Time.mktime(2032)
    unless response_metadata.header['X-RateLimit-Complexity-Reset'].nil?
      complexity_reset = Time.at(response_metadata.header['X-RateLimit-Complexity-Reset'].to_i / 1000)
    end

    unless response_metadata.header['X-RateLimit-Requests-Reset'].nil?
      ratelimit_reset = Time.at(response_metadata.header['X-RateLimit-Requests-Reset'].to_i / 1000)
    end
    stats = {
      last_complexity: @last_complexity,
      complexity_remaining: response_metadata.header['X-RateLimit-Complexity-Remaining'].to_i,
      complexity_reset: complexity_reset,
      requests_remaining: response_metadata.header['X-RateLimit-Requests-Remaining'].to_i,
      requests_reset: ratelimit_reset
    }
    @stats[token] = stats
  end
end