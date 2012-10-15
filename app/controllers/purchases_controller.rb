class PurchasesController < ApplicationController
  before_filter :assign_parent_product, :only => [:new , :create]
  before_filter :bust_response_headers, :only => :new

  def new
    respond_to do |format|
      format.html{
        if country = @ps.ip_country_is_configured?(request.remote_ip)
          @ps.locale = Zaypay::Util.stringify_locale_hash(country[:locale])
        end
      }
      format.js{
        if params[:country].present? && params[:language].present?
          @ps.locale = params[:language] + "-" + params[:country]
        end
      }
    end
  end

  def create
    # set locale first before calling #list_payment_methods
    # locale and payment_method_id must be set before calling create_payment
    
    if params[:language].blank? || params[:country].blank? || params[:payment_method].blank?
      flash[:error] = ''
      flash[:error] << "You did not select a language.<br/>" if params[:language].blank?
      flash[:error] << "You did not select a country.<br/>"   if params[:country].blank?
      flash[:error] << "You did not select a payment method." if params[:payment_method].blank?
      redirect_to new_product_purchase_path(@product) and return
    end
    
    @ps.locale = params[:language] + "-" + params[:country]
    @ps.payment_method_id = params[:payment_method]
    @purchase = @product.purchases.create!
    begin
      @zaypay_payment = @ps.create_payment(:payalogue_id => @product.payalogue_id, :purchase_id => @purchase.id)
    rescue => e
      if e.type == :locale_not_set
        flash[:error] = "There was an error with the country or language you provided"
      elsif e.type == :payment_method_id_not_set
        flash[:error] = "There was an error with the payment method you provided"
      else
        flash[:error] = "Oops... Something went wrong, please try again"
      end
      @purchase.destroy
      redirect_to new_product_purchase_path(@product)
    else
      @purchase.update_attributes(:zaypay_payment_id => @zaypay_payment[:payment][:id])
      redirect_to "https://secure.zaypay.com#{@zaypay_payment[:payment][:payalogue_url]}"
    end
  end

  def report
    if params[:payment_id].present? && params[:price_setting_id].present? && params[:purchase_id].present? && params[:status].present?
      @purchase = Purchase.find(params[:purchase_id])
      @purchase.update_status_by_valid_request(params) if @purchase
    end
    render :layout => false, :text => "*ok*"
  end

  private ################################################################
  def assign_parent_product
    @product = Product.find(params[:product_id])
    @ps = Zaypay::PriceSetting.new(@product.price_setting_id)
  end
  
  def bust_response_headers
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end
end
