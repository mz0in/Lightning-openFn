defmodule Lightning.Accounts.UserNotifierTest do
  use Lightning.DataCase, async: true

  import Swoosh.TestAssertions

  alias Lightning.Accounts.{UserNotifier, User}
  alias Lightning.Projects.Project

  describe "Notification emails" do
    test "deliver_project_addition_notification/2" do
      user = Lightning.AccountsFixtures.user_fixture(email: "user@openfn.org")

      project =
        Lightning.ProjectsFixtures.project_fixture(
          project_users: [%{user_id: user.id}]
        )

      url =
        "#{LightningWeb.Router.Helpers.url(LightningWeb.Endpoint)}/projects/#{project.id}/w"

      UserNotifier.deliver_project_addition_notification(
        user,
        project
      )

      assert_email_sent(
        subject: "Project #{project.name}",
        to: "user@openfn.org",
        text_body:
          "\nHi Anna,\n\nYou've been added to the project \"a-test-project\" as an editor.\n\nClick the link below to check it out:\n\n#{url}\n"
      )
    end

    test "send_deletion_notification_email/1" do
      UserNotifier.send_deletion_notification_email(%User{
        email: "real@email.com"
      })

      assert_email_sent(
        subject: "Lightning Account Deletion",
        to: "real@email.com"
      )
    end

    test "deliver_project_digest/4" do
      user = %User{email: "real@email.com"}
      project = %Project{name: "Real Project"}

      data = [
        %{
          workflow_name: "Workflow A",
          successful_workorders: 12,
          rerun_workorders: 6,
          failed_workorders: 3
        },
        %{
          workflow_name: "Workflow B",
          successful_workorders: 10,
          rerun_workorders: 0,
          failed_workorders: 0
        },
        %{
          workflow_name: "Workflow C",
          successful_workorders: 3,
          rerun_workorders: 0,
          failed_workorders: 7
        }
      ]

      digest_type = :daily

      UserNotifier.deliver_project_digest(user, project, data, digest_type)

      assert_email_sent(
        subject: "Weekly digest for project #{project.name}",
        to: user.email,
        text_body: """
        Workflow A:
        - 12 workorders correctly processed this day
        - 6 failed work orders that were rerun and then processed correctly
        - 3 work orders that failed/still need addressing

        Workflow B:
        - 10 workorders correctly processed this day
        - 0 failed work orders that were rerun and then processed correctly
        - 0 work orders that failed/still need addressing

        Workflow C:
        - 3 workorders correctly processed this day
        - 0 failed work orders that were rerun and then processed correctly
        - 7 work orders that failed/still need addressing

        """
      )
    end
  end
end
