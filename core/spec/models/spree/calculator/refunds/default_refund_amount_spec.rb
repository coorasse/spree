require 'spec_helper'

describe Spree::Calculator::Returns::DefaultRefundAmount do
  let(:order)           { create(:order) }
  let(:line_item_quantity) { 2 }
  let(:pre_tax_amount)  { 100.0 }
  let(:line_item)       { create(:line_item, price: 100.0, quantity: line_item_quantity, pre_tax_amount: pre_tax_amount) }
  let(:inventory_unit) { build(:inventory_unit, order: order, line_item: line_item) }
  let(:return_item) { build(:return_item, inventory_unit: inventory_unit ) }
  let(:calculator) { Spree::Calculator::Returns::DefaultRefundAmount.new }

  before { order.line_items << line_item }

  subject { calculator.compute(return_item) }

  context "not an exchange" do
    context "no promotions or taxes" do
      it { should eq pre_tax_amount / line_item_quantity }
    end

    context "order adjustments" do
      let(:adjustment_amount) { -10.0 }

      before do
        order.adjustments << create(:adjustment, amount: adjustment_amount, eligible: true, label: 'Adjustment', source_type: 'Spree::Order')
        order.adjustments.first.update_attributes(amount: adjustment_amount)
      end

      it { should eq (pre_tax_amount - adjustment_amount.abs) / line_item_quantity }
    end

    context "shipping adjustments" do
      let(:adjustment_total) { -50.0 }

      before { order.shipments << Spree::Shipment.new(adjustment_total: adjustment_total) }

      it { should eq pre_tax_amount / line_item_quantity }
    end
  end

  context "an exchange" do
    let(:return_item) { build(:exchange_return_item) }

    it { should eq 0.0 }
  end

  context "pre_tax_amount is zero" do
    let(:pre_tax_amount)  { 0.0 }
    it { should eq 0.0 }
  end
end
