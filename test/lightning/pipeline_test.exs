defmodule Lightning.PipelineTest do
  use Lightning.DataCase, async: true
  use Mimic

  alias Lightning.Pipeline

  import Lightning.InvocationFixtures
  import Lightning.JobsFixtures
  import Lightning.CredentialsFixtures

  describe "process/1" do
    test "starts a run for a given event and executes it's on_job_failure downstream job" do
      job =
        job_fixture(
          body: ~s[fn(state => { throw new Error("I'm supposed to fail.") })]
        )

      %{id: downstream_job_id} =
        job_fixture(
          trigger: %{type: :on_job_failure, upstream_job_id: job.id},
          body: ~s[fn(state => state)],
          credential_id:
            credential_fixture(
              name: "my credential",
              body: %{"credential" => "body"}
            ).id
        )

      event = event_fixture(job_id: job.id)
      run_fixture(event_id: event.id)

      Pipeline.process(event)

      expected_event =
        from(e in Lightning.Invocation.Event,
          where: e.job_id == ^downstream_job_id,
          preload: [:result_dataclip]
        )
        |> Repo.one!()

      assert %{
               "configuration" => %{"credential" => "body"},
               "data" => %{},
               "error" => error
             } = expected_event.result_dataclip.body

      error = Enum.slice(error, 0..4)

      [
        "╭─────────────────────────────────────────────╮",
        ~r/│ ◲ ◱  @openfn\/core#v1.4.7 \(Node.js v1[\d\.]+\) │/,
        ~r/│ ◳ ◰           @openfn\/language-common@[\d\.]+ │/,
        "╰─────────────────────────────────────────────╯",
        "Error: I'm supposed to fail."
      ]
      |> Enum.zip(error)
      |> Enum.each(fn {m, l} ->
        assert l =~ m
      end)
    end

    test "starts a run for a given event and executes it's on_job_success downstream job" do
      job =
        job_fixture(
          body: ~s[fn(state => { return {...state, extra: "data"} })],
          credential_id: credential_fixture().id
        )

      %{id: downstream_job_id} =
        job_fixture(
          trigger: %{type: :on_job_success, upstream_job_id: job.id},
          name: "on previous job success",
          body: ~s[fn(state => state)],
          credential_id:
            credential_fixture(
              name: "my credential",
              body: %{"credential" => "body"}
            ).id
        )

      event = event_fixture(job_id: job.id)
      run_fixture(event_id: event.id)

      Pipeline.process(event)

      expected_event =
        from(e in Lightning.Invocation.Event,
          where: e.job_id == ^downstream_job_id,
          preload: [:result_dataclip]
        )
        |> Repo.one!()

      assert %{
               "configuration" => %{"credential" => "body"},
               "data" => %{},
               "extra" => "data"
             } == expected_event.result_dataclip.body
    end
  end
end
