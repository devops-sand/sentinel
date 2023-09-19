resource "google_storage_bucket" "dataproc_temp" {
  name     = "dataproc-temp-bucket-${random_id.bucket_suffix.hex}"
  location = "US"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_storage_bucket_object" "wordcount_input" {
  name   = "input/words.txt"
  bucket = google_storage_bucket.dataproc_temp.name
  content = <<EOT
Hello world
Goodbye world
Hello terraform
Goodbye terraform
EOT
}


resource "google_dataproc_workflow_template" "workflow_template" {
  name     = "my-workflow-template"
  location   = "us-central1"

  placement {
    managed_cluster {
      cluster_name = "my-managed-cluster"
      config {
        gce_cluster_config {
          zone = "us-central1-a"
        }
        master_config {
          num_instances   = 1
          machine_type    = "n1-standard-1"
        }
        worker_config {
          num_instances   = 2
          machine_type    = "n1-standard-1"
        }
      }
    }
  }

  jobs {
    step_id   = "wordcount-job"
    hadoop_job {
      main_jar_file_uri = "file:///usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar"
      main_class       = "org.apache.hadoop.examples.WordCount"
      args             = ["gs://${google_storage_bucket.dataproc_temp.name}/input/*", "gs://${google_storage_bucket.dataproc_temp.name}/output/"]
    }
  }

  depends_on = [google_storage_bucket.dataproc_temp]
}


provider "google" {
    
}
