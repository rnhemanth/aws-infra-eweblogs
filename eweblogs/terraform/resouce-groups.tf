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

#Tags 

tags = {
  Name = "emis-eweblogs"
  Environment = var.environment
  Service = var.name.service
  Purpose = "Eweblogs server resource group"
}