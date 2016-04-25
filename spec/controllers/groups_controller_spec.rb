require 'spec_helper'

describe GroupsController do
  describe 'administrator access' do
    let(:grouping) { build_stubbed(:grouping) }
    let(:assignment) { grouping.assignment }

    before :each do
      # Authenticate user is not timed out, and has administrator rights.
      allow(controller).to receive(:session_expired?).and_return(false)
      allow(controller).to receive(:logged_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(build(:admin))

    end

    describe '#note_message'

    describe 'GET #new' do
      before :each do
        allow(Assignment).to receive(:find).and_return(assignment)
      end

      context 'when no group name is specified' do
        it 'adds a new group to assignment' do
          expect(assignment).to receive(:add_group)
            .with(nil)
            .and_return(grouping)
          get :new, assignment_id: assignment
        end
      end

      context 'when a group name is specified' do
        let(:group_name) { 'g2avatar' }

        context 'when group creation successful' do
          it 'creates a new group with specified name' do
            expect(assignment).to receive(:add_group)
              .with(group_name)
              .and_return(grouping)
            get :new, assignment_id: assignment, new_group_name: group_name
          end
        end

        context 'when group creation unsuccessful' do
          before :each do
            allow(assignment).to receive(:add_group)
              .with(group_name)
              .and_raise('Group #{group_name} already exists')

            get :new, assignment_id: assignment, new_group_name: group_name
          end

          it 'assigns the error message to flash[:error]' do
            expect(flash[:error]).to eq('Group #{group_name} already exists')
          end
        end
      end
    end

    describe 'DELETE #remove_group' do
      before :each do
        allow(Grouping).to receive(:find).and_return(grouping)
      end

      context 'when grouping has no submissions' do
        before :each do
          allow(grouping).to receive(:delete_grouping)
          allow(grouping).to receive(:has_submission?).and_return(false)

          delete :remove_group, grouping_id: grouping, assignment_id: assignment
        end

        it 'assigns the requested grouping\'s assignment to @assignment' do
          expect(assigns(:assignment)).to eq(assignment)
        end

        it 'assigns empty array to @errors' do
          expect(assigns(:errors)).to match_array([])
        end

        it 'populates @removed_groupings with deleted groupings' do
          expect(assigns(:removed_groupings)).to match_array([grouping])
        end

        it 'calls grouping.has_submission?' do
          expect(grouping).to receive(:has_submission?).and_return(false)
          delete :remove_group, grouping_id: grouping, assignment_id: assignment
        end

        it 'calls grouping.delete_groupings' do
          expect(grouping).to receive(:delete_grouping)
          delete :remove_group, grouping_id: grouping, assignment_id: assignment
        end
      end

      context 'when grouping has submissions' do
        before :each do
          allow(grouping).to receive(:has_submission?).and_return(true)

          delete :remove_group, grouping_id: grouping, assignment_id: assignment
        end

        it 'assigns the requested grouping\'s assignment to @assignment' do
          expect(assigns(:assignment)).to eq(assignment)
        end

        it 'populates @errors with group_name of grouping\'s group' do
          expect(assigns(:errors)).to match_array([grouping.group.group_name])
        end

        it 'assigns empty array to @removed_groupings' do
          expect(assigns(:removed_groupings)).to match_array([])
        end

        it 'calls grouping.has_submission?' do
          expect(grouping).to receive(:has_submission?).and_return(true)
          delete :remove_group, grouping_id: grouping, assignment_id: assignment
        end
      end
    end

    describe '#rename_group'
    describe '#valid_grouping'
    describe '#invalid_grouping'
    describe '#populate'
    describe '#populate_students'

    describe 'GET #index' do
      before :each do
        allow(Assignment).to receive(:find).and_return(assignment)
        get :index, assignment_id: assignment
      end

      it 'assigns the requested assignment to @assignment' do
        expect(assigns(:assignment)).to eq(assignment)
      end

      it 'renders the :index template' do
        expect(response).to render_template(:index)
      end
    end

    describe '#csv_upload'
    describe '#download_grouplist' do
      before :each do
        # Setup for SubversionRepository
        allow(MarkusConfigurator)
          .to receive(:markus_config_repository_type).and_return('svn')

        @assignment = FactoryGirl.create(:assignment,
                                         allow_web_submits: true,
                                         group_max: 1,
                                         group_min: 1)
        #@grouping = FactoryGirl.create(:grouping, assignment: @assignment)

        @group = FactoryGirl.create(:group)

        @student1 = create(:student, user_name: 'c8shosta')
        @student2 = create(:student, user_name: 'c5bennet')

        grouping = Grouping.new(assignment: @assignment, group: @group)
        grouping.save

        grouping.add_member(@student1, StudentMembership::STATUSES[:inviter])
        grouping.add_member(@student2, StudentMembership::STATUSES[:accepted])

        @ta_name = 'c8shacd'
        @ta = create(:ta, user_name: @ta_name)
        # For each grouping for Assignment 1, assign 2 TAs
        @assignment.groupings.each do |grouping|
          grouping.add_tas([@ta])
        end
      end
      let(:csv_options) do
        {
          type: 'text/csv',
          filename: "#{@assignment.short_identifier}_group_list.csv",
          disposition: 'attachment'
        }
      end

      it 'responds with appropriate status' do
        get :download_grouplist, assignment_id: @assignment.id, format: 'csv'
        expect(response.status).to eq(200)
      end

      # parse header object to check for the right disposition
      it 'sets disposition as attachment' do
        get :download_grouplist, assignment_id: @assignment.id, format: 'csv'
        d = response.header['Content-Disposition'].split.first
        expect(d).to eq 'attachment;'
      end

      it 'expects a call to send_data' do
        csv_data = "#{@group.group_name},#{@group.repo_name}," +
          "#{@student1.user_name},#{@student2.user_name}\n"
        expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
          # to prevent a 'missing template' error
          @controller.render nothing: true
        }
        get :download_grouplist, assignment_id: @assignment.id, format: 'csv'
      end

      # parse header object to check for the right content type
      it 'returns text/csv type' do
        get :download_grouplist, assignment_id: @assignment.id, format: 'csv'
        expect(response.content_type).to eq 'text/csv'
      end

      # parse header object to check for the right file naming convention
      it 'filename passes naming conventions' do
        get :download_grouplist, assignment_id: @assignment.id, format: 'csv'
        filename = response.header['Content-Disposition']
          .split.last.split('"').second
        expect(filename).to eq "#{@assignment.short_identifier}_group_list.csv"
      end
    end

    describe '#use_another_assignment_groups'
    describe '#global_actions'
    describe '#invalidate_groupings'
    describe '#validate_groupings'
    describe '#delete_groupings'
    describe '#add_members'
    describe '#add_member'
    describe '#remove_members'
    describe '#remove_member'
  end
end
