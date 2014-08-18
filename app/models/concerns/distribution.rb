module Distribution
  extend ActiveSupport::Concern

  included do
    include Redis::Objects
  end

  module ClassMethods

    def distribution(*names)
      names.each do |name|
        sorted_set_name = "#{name}_sorted_set"

        sorted_set(sorted_set_name)

        define_method "increase_in_#{name}_distribution" do |value, count = 1|
          send(sorted_set_name).incr(value, count)
        end

        define_method "decrease_in_#{name}_distribution" do |value, count = 1|
          send(sorted_set_name).decr(value, count)
        end

        define_method "#{name}_distribution" do
          responce = send(sorted_set_name).revrangebyscore('+inf', 0, withscores: true)
          # pair = [value, count]
          total_count = responce.inject(0){|sum, pair| sum + pair.last}.to_f
          responce.map!{ |pair| [pair.first, 100 * pair.last / total_count] }
          responce
        end

        define_method "clear_#{name}_distribution" do
          send(sorted_set_name).clear
        end

        define_method "fill_#{name}_distribution" do |values|
          send(sorted_set_name).add_all values
        end

        after_commit "clear_#{name}_distribution", on: :destroy
      end
    end

  end
end