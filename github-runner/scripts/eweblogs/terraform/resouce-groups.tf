resource "aws_resourcegroups_group" "web" {
  name        = "emis-eweblogs"
  description = "All eweblogs servers"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::EC2::Instance"
  ],
  "TagFilters": [
    {
      "Key": "rg_service",
      "Values": ["aws-eweblogs"]
    }
  ]
}
JSON
  }
}