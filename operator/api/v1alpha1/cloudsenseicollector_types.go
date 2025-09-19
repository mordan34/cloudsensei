/*
Copyright 2025.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// EDIT THIS FILE!  THIS IS SCAFFOLDING FOR YOU TO OWN!
// NOTE: json tags are required.  Any new fields you add must have json tags for the fields to be serialized.

// CloudSenseiCollectorSpec defines the desired state of CloudSenseiCollector
// It is designed to be extensible with an array of heterogeneous sources.
type CloudSenseiCollectorSpec struct {
	// sources describes the set of data sources the collector agent should enable.
	// Each entry's Type drives interpretation of the remaining fields.
	// +kubebuilder:validation:MinItems=1
	Sources []SourceSpec `json:"sources"`

	// storage defines where raw payloads (e.g. Loki JSON) are persisted (S3).
	// Optional now, but required for lokiQuery sources to function.
	// +optional
	Storage *StorageSpec `json:"storage,omitempty"`

	// database defines metadata persistence (Postgres).
	// +optional
	Database *DatabaseSpec `json:"database,omitempty"`

	// batching controls generic upstream batching (optional – may be ignored by some source types)
	// +optional
	Batching *BatchingSpec `json:"batching,omitempty"`
}

// SourceType enumerates supported source types.
// +kubebuilder:validation:Enum=metrics;logs;lokiQuery
type SourceType string

const (
	SourceMetrics   SourceType = "metrics"
	SourceLogs      SourceType = "logs"
	SourceLokiQuery SourceType = "lokiQuery"
)

// SourceSpec is a discriminated union; fields are conditionally required
// depending on Type.
type SourceSpec struct {
	// type selects which collector logic to enable.
	// +kubebuilder:validation:Required
	Type SourceType `json:"type"`

	// provider is the underlying implementation (e.g. prometheus, file, loki)
	// +kubebuilder:validation:MinLength=1
	Provider string `json:"provider"`

	// --- Metrics (Type=metrics) ---
	// scrapeInterval for metrics collection (e.g. 30s). RFC3339 duration format accepted by kubebuilder as string.
	// +optional
	ScrapeInterval *metav1.Duration `json:"scrapeInterval,omitempty"`
	// endpoints list Prometheus-compatible endpoints.
	// +optional
	Endpoints []string `json:"endpoints,omitempty"`
	// metrics filter configuration
	// +optional
	Metrics *MetricsFilter `json:"metrics,omitempty"`

	// --- Logs (Type=logs) ---
	// paths glob patterns for log files.
	// +optional
	Paths []string `json:"paths,omitempty"`
	// parseFormat (e.g. json, text)
	// +optional
	ParseFormat string `json:"parseFormat,omitempty"`
	// multilinePattern regex for line starts
	// +optional
	MultilinePattern string `json:"multilinePattern,omitempty"`

	// --- Loki Query (Type=lokiQuery) ---
	// loki connection settings
	// +optional
	Loki *LokiEndpoint `json:"loki,omitempty"`
	// queries to execute when Type=lokiQuery
	// +optional
	Queries []LokiQuery `json:"queries,omitempty"`
}

// MetricsFilter holds include / exclude lists for metric names.
type MetricsFilter struct {
	// +optional
	Include []string `json:"include,omitempty"`
	// +optional
	Exclude []string `json:"exclude,omitempty"`
}

// LokiEndpoint describes where the Loki API resides.
type LokiEndpoint struct {
	// url of the Loki HTTP endpoint (e.g. http://loki:3100)
	// +kubebuilder:validation:Pattern=`^https?://`
	URL string `json:"url"`
}

// LokiQuery describes a single periodic range query.
type LokiQuery struct {
	// expr is a LogQL expression
	// +kubebuilder:validation:MinLength=1
	Expr string `json:"expr"`
	// step duration (e.g. 15s)
	// +kubebuilder:validation:Pattern=`^[0-9]+(s|m|h)$`
	Step string `json:"step"`
	// rangeMinutes lookback window size
	// +kubebuilder:validation:Minimum=1
	RangeMinutes int `json:"rangeMinutes"`
	// limit maximum entries; 0 means default
	// +kubebuilder:validation:Minimum=0
	Limit int `json:"limit"`
	// interval (schedule) between query executions (collector internal)
	// +kubebuilder:validation:Pattern=`^[0-9]+(s|m|h)$`
	Interval string `json:"interval"`
}

// BatchingSpec controls generic batching behavior for upstream ingestion.
type BatchingSpec struct {
	// maxBatchSize number of events per batch
	// +kubebuilder:validation:Minimum=1
	MaxBatchSize int `json:"maxBatchSize"`
	// flushInterval duration (e.g. 15s)
	// +kubebuilder:validation:Pattern=`^[0-9]+(s|m|h)$`
	FlushInterval string `json:"flushInterval"`
	// compression algorithm (gzip|zstd;none)
	// +kubebuilder:validation:Enum=gzip;zstd;none
	Compression string `json:"compression"`
}

// StorageSpec contains object storage configuration (currently S3 only).
type StorageSpec struct {
	// s3 configuration
	// +kubebuilder:validation:Required
	S3 S3Spec `json:"s3"`
}

// S3Spec defines required S3 bucket configuration.
type S3Spec struct {
	// bucket name
	// +kubebuilder:validation:MinLength=3
	Bucket string `json:"bucket"`
	// region (e.g. eu-central-1)
	// +kubebuilder:validation:MinLength=3
	Region string `json:"region"`
	// prefix optional path prefix inside the bucket
	// +optional
	Prefix string `json:"prefix,omitempty"`
	// compression for stored payloads (gzip|none)
	// +kubebuilder:validation:Enum=gzip;none
	// +optional
	Compression string `json:"compression,omitempty"`
	// credentialsSecretRef references a Secret with access credentials
	// +optional
	CredentialsSecretRef *SecretKeyRefTriple `json:"credentialsSecretRef,omitempty"`
}

// SecretKeyRefTriple allows referencing access key id / secret / (optional) session token keys in a single Secret.
type SecretKeyRefTriple struct {
	// name of the Secret
	Name string `json:"name"`
	// accessKeyIdKey key containing AWS access key id
	AccessKeyIdKey string `json:"accessKeyIdKey"`
	// secretAccessKeyKey key containing AWS secret access key
	SecretAccessKeyKey string `json:"secretAccessKeyKey"`
	// sessionTokenKey optional key for session token
	// +optional
	SessionTokenKey string `json:"sessionTokenKey,omitempty"`
}

// DatabaseSpec encapsulates metadata persistence configuration.
type DatabaseSpec struct {
	// postgres configuration
	// +kubebuilder:validation:Required
	Postgres PostgresSpec `json:"postgres"`
}

// PostgresSpec references connection information via Secret (DSN or discrete components).
type PostgresSpec struct {
	// dsnSecretRef references a Secret containing a "dsn" key (postgres connection string)
	// +optional
	DSNSecretRef *SimpleSecretKeyRef `json:"dsnSecretRef,omitempty"`

	// If DSNSecretRef not supplied, the following discrete fields can be used (all required in that case).
	// +optional
	Host string `json:"host,omitempty"`
	// +optional
	Port int `json:"port,omitempty"`
	// +optional
	Database string `json:"database,omitempty"`
	// +optional
	UserSecretRef *SimpleSecretKeyRef `json:"userSecretRef,omitempty"`
	// +optional
	PasswordSecretRef *SimpleSecretKeyRef `json:"passwordSecretRef,omitempty"`
}

// SimpleSecretKeyRef references a single key in a Secret.
type SimpleSecretKeyRef struct {
	Name string `json:"name"`
	Key  string `json:"key"`
}

// CloudSenseiCollectorStatus defines the observed state of CloudSenseiCollector.
type CloudSenseiCollectorStatus struct {
	// observedGeneration reflects the generation most recently acted on
	// +optional
	ObservedGeneration int64 `json:"observedGeneration,omitempty"`

	// phase is a high-level summary of current state
	// +kubebuilder:validation:Enum=Pending;Reconciling;Ready;Error
	// +optional
	Phase string `json:"phase,omitempty"`

	// conditions capture granular status.
	// +listType=map
	// +listMapKey=type
	// +optional
	Conditions []metav1.Condition `json:"conditions,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status

// CloudSenseiCollector is the Schema for the cloudsenseicollectors API
type CloudSenseiCollector struct {
	metav1.TypeMeta `json:",inline"`

	// metadata is a standard object metadata
	// +optional
	metav1.ObjectMeta `json:"metadata,omitempty,omitzero"`

	// spec defines the desired state of CloudSenseiCollector
	// +required
	Spec CloudSenseiCollectorSpec `json:"spec"`

	// status defines the observed state of CloudSenseiCollector
	// +optional
	Status CloudSenseiCollectorStatus `json:"status,omitempty,omitzero"`
}

// +kubebuilder:object:root=true

// CloudSenseiCollectorList contains a list of CloudSenseiCollector
type CloudSenseiCollectorList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []CloudSenseiCollector `json:"items"`
}

func init() {
	SchemeBuilder.Register(&CloudSenseiCollector{}, &CloudSenseiCollectorList{})
}
