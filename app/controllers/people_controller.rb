class PeopleController < ApplicationController
	include PeopleHelper

	breadcrumb Person.model_name.human(count: :other), :people_path

	before_action :set_all_people, only: [:index, :index_as_table]
	before_action :set_person, only: [:show, :addresses, :registrations, :privacy, :payments, :groups,
		:edit, :edit_addresses, :edit_privacy, :edit_payments, :edit_groups, :update, :destroy]
	before_action :basic_authorization

	def index
	end

	def index_as_table
		render "as_table"
	end

	# TODO Optimierung mit "include"
	def show
	end

	def edit
	end

	def edit_addresses
	end

	def edit_privacy
	end

	def edit_payments
	end

	def edit_groups
	end

	def new
		@person = Person.new
		@person_policy = policy(@person)
	end

	def create
		@person = Person.new(permitted_attributes(Person))
		@person_policy = policy(@person)
		if @person.save
			if @person.active
				@person.generate_reset_password_token!
				mailer = AccountMailer.with(person: @person)
				mailer.account_created_email.deliver_now
			end
			redirect_to @person, notice: t('.success')
		else
			render :new
		end
	end

	def update
		if @person.update(permitted_attributes(@person))
			redirect_to @person, notice: t('.success')
		else
			pages = ['edit', 'edit_addresses', 'edit_payments', 'edit_privacy']
			action = pages.include?(params[:formular]) ? params[:formular] : 'edit'
			render action
		end
	end

	def destroy
		authorize @person, :delete_person?
		@person.destroy
		redirect_to people_url, notice: t('.success')
	end
private
	def set_person
		@person = policy_scope(Person).find(params[:id])
		@person_policy = policy(@person)
		breadcrumb @person.full_name, @person
		breadcrumb t('actions.person.' + action_name), {action: action_name}
	end

	def set_all_people
		@people = policy_scope(Person).includes(:addresses, :contacts)
		@person_policy = policy(Person)
	end

	def basic_authorization
		case action_name.to_sym
			when :show, :registrations
				authorize @person, :view_public?
			when :privacy, :groups
				authorize @person, :view_settings?
			when :payments
				authorize @person, :view_payments?
			when :addresses
				authorize @person, :view_additional?
			when :edit, :update
				authorize @person, :edit_basic?
			when :edit_privacy
				authorize @person, :edit_settings?
			when :edit_payments
				authorize @person, :edit_payments?
			when :edit_addresses
				authorize @person, :edit_additional?
			when :new, :create
				authorize Person, :create_person?
			when :index, :index_as_table
				authorize Person, :list_published_people?
			when :destroy
				authorize @person, :delete_person?
			else
				raise Pundit::NotAuthorizedError({query: action_name, record: @person})
		end
	end
end
