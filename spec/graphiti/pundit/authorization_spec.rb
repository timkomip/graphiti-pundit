# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphiti::Pundit::Authorization do
  include_context "resource testing"

  let(:resource) { PersonResource }
  let(:action_name) { :index }
  let(:current_user) { :john }
  let(:base_scope) { :base_scope }

  def graphiti_context
    @graphiti_context ||= begin
      ctx = OpenStruct.new
      ctx.current_user = current_user if respond_to?(:current_user)
      ctx.params = params
      ctx.action_name = action_name
      ctx
    end
  end

  describe "#authorize_resource" do
    context "user has permission" do
      it "can view all records" do
        expect(Pundit).to receive(:authorize).with(current_user, base_scope, "#{action_name}?",
          {cache: anything, policy_class: anything})
        expect(records).to eq Person.all
      end
    end

    context "user does not have permission" do
      it "raises unauthorized error" do
        expect(Pundit).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
        expect { records }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
