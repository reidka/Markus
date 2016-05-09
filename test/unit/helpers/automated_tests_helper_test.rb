require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'helper'))
include AutomatedTestsHelper
require 'shoulda'

class AutomatedTestsHelperTest < ActiveSupport::TestCase

  def teardown
  end

  # TODO: Previously, we have all the helper functions as instance functions,
  # and the following tests work. However, After we changed them to
  # class functions, the tests are broken down. Please modify the tests
  # so that they work.
  # Also, please add tests to test the helper function 'process_result'

=begin
  context 'Given the required files, MarkUs' do
    setup do
      @asst = Assignment.make
      @asst.short_identifier = 'Tmp'

      @scriptfile  = TestScript.make(:assignment_id           => @asst.id,
                                     :seq_num                 => 2,
                                     :script_name             => 'test1.rb',
                                     :description             => 'This is an easy test',
                                     :max_marks               => 2,
                                     :run_on_submission       => false,
                                     :run_on_request          => true,
                                     :halts_testing           => false,
                                     :display_description     => 'display_after_submission',
                                     :display_run_status      => 'display_after_submission',
                                     :display_marks_earned    => 'do_not_display',
                                     :display_input           => 'do_not_display',
                                     :display_expected_output => 'do_not_display',
                                     :display_actual_output   => 'do_not_display')
      @scriptfile2 = TestScript.make(:assignment_id           => @asst.id,
                                     :seq_num                 => 1,
                                     :script_name             => 'pretest.rb',
                                     :description             => 'This is a test with no mark, can be a pretest, compile test etc.',
                                     :max_marks               => 0,
                                     :run_on_submission       => true,
                                     :run_on_request          => true,
                                     :halts_testing           => false,
                                     :display_description     => 'display_after_submission',
                                     :display_run_status      => 'display_after_submission',
                                     :display_marks_earned    => 'display_after_submission',
                                     :display_input           => 'do_not_display',
                                     :display_expected_output => 'do_not_display',
                                     :display_actual_output   => 'do_not_display')
      @scriptfile3 = TestScript.make(:assignment_id           => @asst.id,
                                     :seq_num                 => 3,
                                     :script_name             => 'test2.rb',
                                     :description             => 'This is a hard test',
                                     :max_marks               => 10,
                                     :run_on_submission       => false,
                                     :run_on_request          => false,
                                     :halts_testing           => false,
                                     :display_description     => 'do_not_display',
                                     :display_run_status      => 'do_not_display',
                                     :display_marks_earned    => 'do_not_display',
                                     :display_input           => 'do_not_display',
                                     :display_expected_output => 'do_not_display',
                                     :display_actual_output   => 'do_not_display')

    end

    should 'be able to return all test scripts when automated test is requested at collection' do
      @call_on = 'collection'
      scripts = AutomatedTestsHelper.scripts_to_run(@asst, @call_on)
      assert_equal scripts.size, 3
      assert_equal scripts[0], @scriptfile2, 'The test scripts should be sorted in seq_num order'
      assert_equal scripts[1], @scriptfile, 'The test scripts should be sorted in seq_num order'
      assert_equal scripts[2], @scriptfile3, 'The test scripts should be sorted in seq_num order'
    end

    should 'be able to return a list of test scripts to run when automated test is requested' do
      @call_on = 'request'
      scripts = AutomatedTestsHelper.scripts_to_run(@asst, @call_on)
      assert_equal scripts.size, 2
      assert_equal scripts[0], @scriptfile2, 'The test scripts should be sorted in seq_num order'
      assert_equal scripts[1], @scriptfile, 'The test scripts should be sorted in seq_num order'
    end

    should 'be able to return a list of test scripts to run when submission received' do
      @call_on = 'submission'
      scripts = AutomatedTestsHelper.scripts_to_run(@asst, @call_on)
      assert_equal scripts.size, 1
      assert_equal scripts[0], @scriptfile2
    end
  end

  context 'A user' do
    setup do
      @group = Group.make
      @group.repo_name = 'Group_Tmp'
      @repo_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, @group.repo_name)
    end

    should 'be able to delete the test repository' do
      AutomatedTestsHelper.delete_test_repo(@repo_dir)
      assert !File.exists?(@repo_dir)
    end

    should 'be able to export the test repository' do
      assert AutomatedTestsHelper.export_group_repo(@group, @repo_dir)
    end
  end

  context 'An admin' do
    setup do
      @admin = Admin.make
      @current_user = @admin
    end
    should 'be allowed to do automated test' do
      assert AutomatedTestsHelper.has_permission?
    end
  end

  context 'A TA' do
    setup do
      @ta = Ta.make
      @current_user = @ta
    end
    should 'be allowed to do automated test' do
      assert AutomatedTestsHelper.has_permission?
    end
  end

  context 'A student with sufficient tokens' do
    setup do
      @student = Student.make
      @token = Token.make
      @token.grouping_id = 2
      @token.remaining = 3
      @token.save
      @grouping = Grouping.make(:id => '2')
      @grouping.add_member(@student)
      @current_user = @student
    end
    should 'be allowed to do automated test' do
      assert AutomatedTestsHelper.has_permission?
    end
  end

  context 'A student without any tokens' do
    setup do
      @student = Student.make
      @token = Token.make
      @token.grouping_id = 2
      @token.remaining = 0
      @token.save
      @grouping = Grouping.make(:id => '2')
      @grouping.add_member(@student)
      @current_user = @student
    end
    should 'not be allowed to do automated test' do
      assert_raise(RuntimeError) do
        AutomatedTestsHelper.has_permission? # raises exception
      end
    end
  end

  context 'A student allowed to do automated test but without a token object' do
    setup do
      @student = Student.make
      @token = Token.make
      @token.grouping_id = 2
      @token.remaining = nil
      @token.save
      @grouping = Grouping.make(:id => '2')
      @grouping.add_member(@student)
      @current_user = @student
    end
    should 'not be allowed to do test (no tokens are found for this student)' do
      assert_raise(RuntimeError) do
        AutomatedTestsHelper.has_permission? # raises exception
      end
    end
  end

  context 'A student' do
    setup do
      @student = Student.make
      @token = Token.make
      @token.grouping_id = 2
      @token.remaining = nil
      @token.save
      @current_user = @student
    end
    should 'not be allowed to run automated tests on a group they do not belong to' do
      assert_raise(RuntimeError) do
        AutomatedTestsHelper.has_permission? # raises exception
      end
    end
  end

  context 'A user' do
    setup do
      @assignment = Assignment.make
      @assignment.short_identifier = 'Tmp'
      @group = Group.make
      @group.repo_name = 'Group_Tmp'
      @repo_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, @group.repo_name)
      @test_dir = File.join(MarkusConfigurator.markus_config_automated_tests_repository, @assignment.short_identifier)
    end

    should 'not be allowed to run automated tests if no test script file is available' do
      delete_test_repo(@test_dir)
      assert_raise(RuntimeError) do
        AutomatedTestsHelper.files_available? # raises exception
      end
    end

    should 'not be allowed to run automated tests if no source file is available' do
      delete_test_repo(@repo_dir)
      assert_raise(RuntimeError) do
        AutomatedTestsHelper.files_available? # raises exception
      end
    end

    should 'be able to run automated tests if test script files and source files are presented' do
      @aScript = TestScript.make
      @aScript.assignment_id = @assignment.id
      @aScript.save
      FileUtils.makedirs(@test_dir)
      FileUtils.makedirs(@repo_dir)
      assert AutomatedTestsHelper.files_available?
    end
  end

  context 'MarkUs' do
    should 'return 0, the index of the first available test server.' do
      # @last_server is not yet defined here
      assert_equal AutomatedTestsHelper.choose_test_server, 0
    end

    should 'return the index of an available test server, if there is at least one available' do
      @last_server = 0
      server_id = AutomatedTestsHelper.choose_test_server
      assert server_id >= 0
      assert server_id < MarkusConfigurator.markus_ate_num_test_servers
    end

    should 'return 0, if last_server is the last test server in the list' do
      @last_server = MarkusConfigurator.markus_ate_num_test_servers - 1
      assert_equal AutomatedTestsHelper.choose_test_server, 0
    end

    #should 'return -1 if there is no available test server' do
    #  #TODO: this fails because no implementation checking the max num of tests running on a server yet
    #  assert_equal choose_test_server, -1
    #end
  end
=end
end
