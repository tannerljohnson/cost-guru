class GraphHelpers
  def self.format_cost_and_usage(cost_and_usage_data)
    # INPUT
    # [
    #   {
    #   :start=>"2023-12-17",
    #   :total=>52586.96,
    #   :groups=> [
    #       ["AWS Cloud Map", 0.0],
    #       ["AWS CloudTrail", 0.0],
    #       ["AWS CodeArtifact", 0.0]
    #     ]
    #   }
    # ]
    #
    # OR
    #
    #  [{:start=>"2023-12-14", :total=>73540.25, :groups=>[]},
    #  {:start=>"2023-12-15", :total=>69740.66, :groups=>[]},
    #  {:start=>"2023-12-16", :total=>54981.15, :groups=>[]},
    #  {:start=>"2023-12-17", :total=>52586.98, :groups=>[]}]

    # OUTPUT:
    # [
    #   {name: "confluent", data: ['2023-12-02', 109800.20]},
    #   {name: "cohere", data: ['2023-12-02', 109800.20]}
    # ]

    if cost_and_usage_data.first.fetch(:groups).empty?
      return [
        { name: "Total", data: cost_and_usage_data.map { |result_by_time| [result_by_time.fetch(:start), result_by_time.fetch(:total)] } }
      ]
    end

    # TODO: implment this
    cost_and_usage_data.map do |result_by_time|
      1
    end
  end
end
