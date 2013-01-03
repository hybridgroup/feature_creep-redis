class FeatureCreep
  class RedisDataStore

    def initialize(datastore = nil, key_prefix = "feature_creep")
      @key_prefix = key_prefix
      @redis = datastore || Redis.new
    end

    # Activate Methods
    def activate_globally(feature)
      @redis.sadd(global_key, feature)
    end

    def activate_scope(feature, scope)
      @redis.sadd(scope_key(feature), scope)
    end

    def activate_individual(feature, individual)
      @redis.sadd(individual_key(feature), individual)
    end

    def activate_percentage(feature, percentage)
      @redis.set(percentage_key(feature), percentage)
    end

    # Deactivate Methods
    def deactivate_globally(feature)
      @redis.srem(global_key, feature)
    end

    def deactivate_scope(feature, scope)
      @redis.srem(scope_key(feature), scope)
    end

    def deactivate_individual(feature, individual)
      @redis.srem(individual_key(feature), individual)
    end

    def deactivate_percentage(feature)
      @redis.del(percentage_key(feature))
    end

    def deactivate_all(feature)
      @redis.del(scope_key(feature))
      @redis.del(individual_key(feature))
      @redis.del(percentage_key(feature))
      deactivate_globally(feature)
    end

    # Reporting Methods
    def active_global_features
      (@redis.smembers(global_key) || []).map(&:to_sym)
    end

    def active_scopes(feature)
      @redis.smembers(scope_key(feature)) || []
    end

    def active_individuals(feature)
      @redis.smembers(individual_key(feature))
    end

    def active_percentage(feature)
      @redis.get(percentage_key(feature))
    end

    # Boolean Methods
    def active_globally?(feature)
      @redis.sismember(global_key, feature)
    end

    def individual_active?(feature, individual)
      @redis.sismember(individual_key(feature), individual)
    end

    def individual_within_active_percentage?(feature, individual)
      percentage = active_percentage(feature)
      return false if percentage.nil?
      individual % 100 < percentage.to_i
    end

    # Utility Methods
    def features
      @redis.smembers(@key_prefix).map(&:to_sym)
    end

    def add_feature(feature)
      @redis.sadd(@key_prefix, feature)
    end

    def remove_feature(feature)
      @redis.srem(@key_prefix, feature)
    end

    private
    def key(name)
      "#{@key_prefix}:#{name}"
    end

    def scope_key(name)
      "#{key(name)}:scopes"
    end

    def individual_key(name)
      "#{key(name)}:individuals"
    end

    def percentage_key(name)
      "#{key(name)}:percentage"
    end

    def global_key
      "#{@key_prefix}:__global__"
    end
  end
end
