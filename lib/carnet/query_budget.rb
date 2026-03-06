# frozen_string_literal: true

module Carnet
  # Counts SQL queries fired inside a block and
  # either warns or raises when the count exceeds a
  # configurable budget. Wraps permission-check
  # methods so each resolves in a bounded number of
  # round-trips to the database.
  module QueryBudget
    # Exception raised in :raise mode when the budget
    # is blown.
    class Exceeded < Carnet::Error
      attr_reader :budget, :method_name,
        :queries, :query_count

      def initialize(method_name, query_count, budget,
        queries)
        @method_name = method_name
        @query_count = query_count
        @budget = budget
        @queries = queries
        super(build_message)
      end

      private

      def build_message
        noun = (query_count == 1) ? "query" : "queries"
        listing = queries.each_with_index.map do |sql, i|
          "  #{i + 1}. #{sql}"
        end
        "#{method_name} executed #{query_count} " \
          "#{noun} (budget: #{budget})\n" \
          "#{listing.join("\n")}"
      end
    end

    # Subscribes to ActiveSupport::Notifications for
    # sql.active_record and tallies non-cached,
    # non-schema queries that fire during #track.
    class Counter
      attr_reader :queries

      def initialize
        @queries = []
      end

      # @return [Integer]
      def count
        queries.length
      end

      # Yields the block while recording queries.
      def track
        sub = ActiveSupport::Notifications
          .subscribe("sql.active_record") do |event|
            pl = event.payload
            next if pl[:cached]
            next if pl[:name] == "SCHEMA"
            next if pl[:name] == "EXPLAIN"

            @queries << pl[:sql]
          end

        yield
      ensure
        ActiveSupport::Notifications.unsubscribe(sub)
      end
    end

    class << self
      # Run +block+ under query-budget monitoring.
      # Returns whatever the block returns.
      def enforce(method_name, mode: :off, budget: 1,
        &block)
        return yield if mode == :off

        ctr = Counter.new
        result = ctr.track(&block)

        on_exceeded(method_name, ctr, budget, mode) if ctr.count > budget

        result
      end

      private

      def on_exceeded(label, counter, budget, mode)
        case mode
        when :warn
          log_exceeded(label, counter, budget)
        when :raise
          raise Exceeded.new(
            label, counter.count,
            budget, counter.queries
          )
        end
      end

      def log_exceeded(label, counter, budget)
        noun = (counter.count == 1) ? "query" : "queries"
        Carnet.logger&.warn(
          "[Carnet] Query budget exceeded: " \
          "#{label} executed " \
          "#{counter.count} #{noun} " \
          "(budget: #{budget})"
        )
        counter.queries.each_with_index do |sql, idx|
          Carnet.logger&.warn("  #{idx + 1}. #{sql}")
        end
      end
    end
  end
end
