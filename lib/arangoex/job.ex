defmodule Arangoex.Job do
  @moduledoc "ArangoDB Job methods"

  # GET /_api/job/{job-id} Returns async job
  # PUT /_api/job/{job-id} Return result of an async job
  # PUT /_api/job/{job-id}/cancel Cancel async job
  # DELETE /_api/job/{type} Deletes async job
  # GET /_api/job/{type} Returns list of async jobs
end
