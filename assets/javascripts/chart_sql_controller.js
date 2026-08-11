import { Controller } from "@hotwired/stimulus";
import { application } from "controllers/application";

application.register(
  "chart-sql",
  class extends Controller {
    static targets = ["config", "canvas"];

    connect() {
      const chartConfig = JSON.parse(this.configTarget.content.textContent);
      import("chart.js").then(
        (chart) => new chart.default(this.canvasTarget, chartConfig),
      );
    }
  },
);
