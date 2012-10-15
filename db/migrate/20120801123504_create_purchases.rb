class CreatePurchases < ActiveRecord::Migration
  def change
    create_table :purchases do |t|
      t.integer :product_id
      t.integer :zaypay_payment_id
      t.string :status, :default => "prepared"

      t.timestamps
    end
  end
end
