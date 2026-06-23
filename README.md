# MARC Duplicate Record Validation

This is a command line tool that helps us validate
MARC record deduplication algorithms.

When you supply it with a list of known duplicate
records, it can do one of two things:
* It can download the records for you, so that you
  can process them using the algorithm of your choice.
* You can compare it with the list of duplicates that
  your algorithm found to understand how accurate it
  was.

The format for duplicates is a "clusters" key pointing to an
array containing 0 to many arrays.  Each
inner array represents a cluster of duplicate records as their string IDs.

```json
{
   "clusters": [
        ["9996192723506421", "SCSB-13600285", "SCSB-12806464", "SCSB-9153556"],
        ["9996061473506421", "SCSB-13548865", "SCSB-10956306", "SCSB-14380232"]
    ]
}
```
