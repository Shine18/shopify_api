module ShopifyAPI
  class FulfillmentOrder < Base
    def self.find(scope, *args)
      if scope == :all
        order_id = args.first&.dig(:params, :order_id)
        raise ShopifyAPI::ValidationException, "'order_id' is required" if order_id.blank?

        order = ::ShopifyAPI::Order.new(id: order_id)
        order.fulfillment_orders(args.first[:params].except(:order_id))
      else
        super(scope, *args)
      end
    end

    def fulfillments(options = {})
      fulfillment_hashes = get(:fulfillments, options)
      fulfillment_hashes.map { |fulfillment_hash| Fulfillment.new(fulfillment_hash) }
    end

    def move(new_location_id:)
      body = {
        fulfillment_order: {
          new_location_id: new_location_id
        }
      }
      keyed_fulfillment_orders = keyed_fulfillment_orders_from_response(post(:move, {}, body.to_json))
      load_keyed_fulfillment_order(keyed_fulfillment_orders, 'original_fulfillment_order')
      keyed_fulfillment_orders
    end

    def cancel
      keyed_fulfillment_orders = keyed_fulfillment_orders_from_response(post(:cancel, {}, only_id))
      load_keyed_fulfillment_order(keyed_fulfillment_orders, 'fulfillment_order')
      keyed_fulfillment_orders
    end

    def close(message: nil)
      body = {
        fulfillment_order: {
          message: message
        }
      }
      load_attributes_from_response(post(:close, {}, body.to_json))
    end

    private

    def load_keyed_fulfillment_order(keyed_fulfillment_orders, key)
      if keyed_fulfillment_orders[key]&.attributes
        load(keyed_fulfillment_orders[key].attributes, false, true)
      end
    end

    def keyed_fulfillment_orders_from_response(response)
      return load_attributes_from_response(response) if response.code != '200'

      keyed_fulfillment_orders = ActiveSupport::JSON.decode(response.body)
      keyed_fulfillment_orders.transform_values do |fulfillment_order_attributes|
        FulfillmentOrder.new(fulfillment_order_attributes) if fulfillment_order_attributes
      end
    end
  end
end
