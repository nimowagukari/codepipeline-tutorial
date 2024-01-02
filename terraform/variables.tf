variable "exist" {
  type = bool
  description = "リソース存在フラグ。金かかるリソースは tfvars で無効化する"
  default = true
}
