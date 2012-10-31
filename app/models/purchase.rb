class Purchase < ActiveRecord::Base
  belongs_to :product

  def update_status_by_valid_request(params)
    return if !payment_id_equals?(params[:payment_id]) || !price_setting_id_equals?(params[:price_setting_id]) || !status_equals?(params[:status])
    update_attributes(:status => params[:status])
  end

  private
  def payment_id_equals?(params_payment_id)
    zaypay_payment_id == params_payment_id.to_i
  end
  
  def price_setting_id_equals?(params_price_setting_id)
    product.price_setting_id == params_price_setting_id.to_i
  end
  
  def status_equals?(params_status)
    @ps = Zaypay::PriceSetting.new(product.price_setting_id)
    @zaypay_payment = @ps.show_payment(zaypay_payment_id)
    @zaypay_payment[:payment][:status] == params_status
  end
end