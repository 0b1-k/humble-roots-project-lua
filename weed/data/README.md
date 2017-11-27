**InfluxDB database backups**

Each .zip file in this folder contains a complete influxDB database snapshot with sensor and
event data as they were recorded during a grow cycle. The filename corresponds the strain grown during that cycle.

For instructions on how to restore this data to your own
influxDB instance, see 
this [page](https://docs.influxdata.com/influxdb/v1.1/administration/backup_and_restore/).

Once restored, you can explore the data through [Grafana](http://grafana.org/) 
using the dashboards provided under /dashboard/grafana.
