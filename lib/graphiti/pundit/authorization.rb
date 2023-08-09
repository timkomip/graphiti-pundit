# frozen_string_literal: true

module Graphiti
  module Pundit
    module Authorization
      extend ActiveSupport::Concern

      included do
        before_save only: :create do |model, _args|
          authorize model if authorization_enabled?
        end
      end

      class_methods do
        def authorize_resource
          @authorization_enabled = true
        end

        def authorization_enabled?
          @authorization_enabled
        end
      end

      def authorization_enabled?
        self.class.authorization_enabled?
      end

      # This is a method override of Graphiti::Resource#before_resolve
      def before_resolve(scope, query)
        authorize scope if self.class.authorization_enabled?

        super
      end

      protected

      # @return [Boolean] whether authorization has been performed, i.e. whether
      #                   one {#authorize} or {#skip_authorization} has been called
      def pundit_policy_authorized?
        !!@_pundit_policy_authorized
      end

      # @return [Boolean] whether policy scoping has been performed, i.e. whether
      #                   one {#policy_scope} or {#skip_policy_scope} has been called
      def pundit_policy_scoped?
        !!@_pundit_policy_scoped
      end

      # Raises an error if authorization has not been performed, usually used as an
      # `after_action` filter to prevent programmer error in forgetting to call
      # {#authorize} or {#skip_authorization}.
      #
      # @see https://github.com/varvet/pundit#ensuring-policies-and-scopes-are-used
      # @raise [AuthorizationNotPerformedError] if authorization has not been performed
      # @return [void]
      def verify_authorized
        raise AuthorizationNotPerformedError, self.class unless pundit_policy_authorized?
      end

      # Raises an error if policy scoping has not been performed, usually used as an
      # `after_action` filter to prevent programmer error in forgetting to call
      # {#policy_scope} or {#skip_policy_scope} in index actions.
      #
      # @see https://github.com/varvet/pundit#ensuring-policies-and-scopes-are-used
      # @raise [AuthorizationNotPerformedError] if policy scoping has not been performed
      # @return [void]
      def verify_policy_scoped
        raise PolicyScopingNotPerformedError, self.class unless pundit_policy_scoped?
      end

      # Retrieves the policy for the given record, initializing it with the record
      # and current user and finally throwing an error if the user is not
      # authorized to perform the given action.
      #
      # @param record [Object, Array] the object we're checking permissions of
      # @param query [Symbol, String] the predicate method to check on the policy (e.g. `:show?`).
      #   If omitted then this defaults to the Rails controller action name.
      # @param policy_class [Class] the policy class we want to force use of
      # @raise [NotAuthorizedError] if the given query method returned false
      # @return [Object] Always returns the passed object record
      def authorize(record, query = nil, policy_class: nil)
        query ||= "#{action_name}?"

        @_pundit_policy_authorized = true

        ::Pundit.authorize(pundit_user, record, query, policy_class: policy_class, cache: policies)
      end

      # Allow this action not to perform authorization.
      #
      # @see https://github.com/varvet/pundit#ensuring-policies-and-scopes-are-used
      # @return [void]
      def skip_authorization
        @_pundit_policy_authorized = :skipped
      end

      # Allow this action not to perform policy scoping.
      #
      # @see https://github.com/varvet/pundit#ensuring-policies-and-scopes-are-used
      # @return [void]
      def skip_policy_scope
        @_pundit_policy_scoped = :skipped
      end

      # Retrieves the policy scope for the given record.
      #
      # @see https://github.com/varvet/pundit#scopes
      # @param scope [Object] the object we're retrieving the policy scope for
      # @param policy_scope_class [Class] the policy scope class we want to force use of
      # @return [Scope{#resolve}, nil] instance of scope class which can resolve to a scope
      def policy_scope(scope, policy_scope_class: nil)
        @_pundit_policy_scoped = true
        policy_scope_class ? policy_scope_class.new(pundit_user, scope).resolve : pundit_policy_scope(scope)
      end

      # Retrieves the policy for the given record.
      #
      # @see https://github.com/varvet/pundit#policies
      # @param record [Object] the object we're retrieving the policy for
      # @return [Object, nil] instance of policy class with query methods
      def policy(record)
        policies[record] ||= Pundit.policy!(pundit_user, record)
      end

      # Cache of policies. You should not rely on this method.
      #
      # @api private
      # rubocop:disable Naming/MemoizedInstanceVariableName
      def policies
        @_pundit_policies ||= {}
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName

      # Cache of policy scope. You should not rely on this method.
      #
      # @api private
      # rubocop:disable Naming/MemoizedInstanceVariableName
      def policy_scopes
        @_pundit_policy_scopes ||= {}
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName

      # Hook method which allows customizing which user is passed to policies and
      # scopes initialized by {#authorize}, {#policy} and {#policy_scope}.
      #
      # @see https://github.com/varvet/pundit#customize-pundit-user
      # @return [Object] the user object to be used with pundit
      def pundit_user
        current_user
      end

      def action_name
        context.action_name
      end

      private

      def pundit_policy_scope(scope)
        policy_scopes[scope] ||= Pundit.policy_scope!(pundit_user, scope)
      end
    end
  end
end
