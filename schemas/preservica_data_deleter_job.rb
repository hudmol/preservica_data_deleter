{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "delete" => {"type" => "boolean", "default" => false},
      "confirmation_string" => {"type" => "string", "maxLength" => 255}
    }
  }
}
