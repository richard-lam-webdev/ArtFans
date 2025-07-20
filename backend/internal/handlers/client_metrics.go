package handlers

import (
	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	clientPageLoad = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "client_page_load_duration_ms",
		Help:    "Page load duration in milliseconds",
		Buckets: []float64{100, 250, 500, 1000, 2500, 5000, 10000},
	}, []string{"platform", "page"})

	clientAPILatency = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "client_api_latency_ms",
		Help:    "Client-side API call latency",
		Buckets: []float64{50, 100, 250, 500, 1000, 2500, 5000},
	}, []string{"platform", "endpoint"})

	clientErrors = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "client_errors_total",
		Help: "Total client-side errors",
	}, []string{"platform", "error_type"})
)

type ClientMetric struct {
	Type   string            `json:"type"`
	Value  float64           `json:"value"`
	Labels map[string]string `json:"labels"`
}

func ClientMetricsHandler(c *gin.Context) {
	var metric ClientMetric

	if err := c.ShouldBindJSON(&metric); err != nil {
		c.JSON(400, gin.H{"error": "Invalid metric"})
		return
	}

	switch metric.Type {
	case "page_load":
		clientPageLoad.With(metric.Labels).Observe(metric.Value)
	case "api_latency":
		clientAPILatency.With(metric.Labels).Observe(metric.Value)
	case "error":
		clientErrors.With(metric.Labels).Inc()
	}

	c.Status(204)
}
