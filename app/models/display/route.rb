module Display
  class Route
    attr_accessor :route, :directions

    delegate :color, :text_color, :name, :alternate_name, :internal_id, :visible?, :scheduled?, to: :route

    def initialize(route, stop_times, timestamp, stops)
      @route = route
      @directions = {
        1 => Display::RouteDirection.new(route.internal_id, 1, stop_times, timestamp, stops),
        3 => Display::RouteDirection.new(route.internal_id, 3, stop_times, timestamp, stops),
      }
      @unavailable = false
    end

    def push_trip(trip)
      directions[trip.direction].push_trip(trip)
    end

    def status
      return "No Data" if unavailable

      if delay >= 5
        "Delay"
      elsif max_headway_discreprency.nil?
        if route.scheduled?
          "No Service"
        else
          "Not Scheduled"
        end
      elsif directions.any? {|_, d| d.lines_not_in_service.present? || d.line_directions.any? { |ld| ld.max_actual_headway.present? && ld.max_scheduled_headway.nil? } }
        "Service Change"
      elsif max_headway_discreprency > 2
        "Not Good"
      else
        "Good Service"
      end
    end

    def max_headway_discreprency
      directions.map { |_, rd|
        rd.headway_discreprency
      }.reject { |headway_discreprency|
        headway_discreprency.nil?
      }.max
    end

    def set_unavailable!
      @unavailable = true
    end

    private

    attr_accessor :trips, :unavailable

    def delay
      directions.map { |_, rd|
        rd.delay
      }.max || 0
    end
  end
end