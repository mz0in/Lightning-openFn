defmodule LightningWeb.RunLive.Index do
  @moduledoc """
  Index Liveview for Runs
  """
  use LightningWeb, :live_view

  alias Lightning.Invocation
  alias Lightning.Invocation.Run

  alias Lightning.Invocation.RunSearchForm
  alias Lightning.Invocation.RunSearchForm.RunStatusOption

  on_mount {LightningWeb.Hooks, :project_scope}

  @impl true
  def handle_info({:updated_options, statuses}, socket) do
    {:noreply,
     socket
     |> assign(:changeset, build_search_changeset(statuses))
     |> assign(:statuses, statuses)}
  end

  @impl true
  def mount(_params, _session, socket) do
    statuses = [
      %RunStatusOption{id: 1, label: "Success", selected: true},
      %RunStatusOption{id: 2, label: "Failure", selected: true},
      %RunStatusOption{id: 3, label: "Timeout", selected: true},
      %RunStatusOption{id: 3, label: "Crash", selected: true}
    ]

    workflows = []

    {:ok,
     socket
     |> assign(:changeset, build_search_changeset(statuses))
     |> assign(:workflows, workflows)
     |> assign(:statuses, statuses)
     |> assign(
       active_menu_item: :runs,
       work_orders: [],
       pagination_path:
         &Routes.project_run_index_path(
           socket,
           :index,
           socket.assigns.project,
           &1
         )
     )}
  end

  defp build_search_changeset(statuses) do
    %RunSearchForm{}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:options, statuses)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(
      page_title: "Runs",
      run: %Run{},
      page:
        Invocation.list_work_orders_for_project(socket.assigns.project, params)
    )
  end
end
