# Budget refusal demo

Throwaway pull request for a live check of the per-PR `/oc` budget. Do not merge.

The workflow allows three admitted model runs per pull request. The fourth `/oc`
must skip the model and publish a report with `limit_exhausted`, the current head
SHA and a link to the run.
