# Terraform Destroy 故障排除指南

## 🚨 常见销毁问题及解决方案

### 问题1：Helm Release 删除失败

**错误信息：**
```
Error: failed to delete release: aws-load-balancer-controller
```

**解决方案：**

#### 方法1：使用清理脚本（推荐）
```bash
# 运行预清理脚本
./scripts/pre-destroy-cleanup.sh

# 然后执行销毁
terraform destroy -auto-approve
```

#### 方法2：手动清理
```bash
# 1. 更新 kubeconfig
aws eks update-kubeconfig --region us-west-2 --name my-project-eks-cluster

# 2. 删除 ALB Controller
helm uninstall aws-load-balancer-controller -n kube-system

# 3. 删除所有 LoadBalancer 服务
kubectl get svc --all-namespaces -o wide | grep LoadBalancer
kubectl delete svc <service-name> -n <namespace>

# 4. 删除所有 Ingress
kubectl get ingress --all-namespaces
kubectl delete ingress <ingress-name> -n <namespace>

# 5. 等待 AWS 资源清理
sleep 30

# 6. 执行 Terraform 销毁
terraform destroy -auto-approve
```

### 问题2：Kubernetes 资源无法访问

**错误信息：**
```
Error: Unauthorized
the server has asked for the client to provide credentials
```

**解决方案：**

#### 方法1：分步骤销毁
```bash
# 1. 先销毁 Kubernetes 相关资源
terraform destroy -target=module.eks.helm_release.aws_load_balancer_controller
terraform destroy -target=module.eks.kubernetes_service_account.aws_load_balancer_controller

# 2. 再销毁 EKS 集群
terraform destroy -target=module.eks

# 3. 最后销毁其他资源
terraform destroy
```

#### 方法2：强制销毁
```bash
# 跳过 Kubernetes provider 验证
export KUBE_CONFIG_PATH=""
terraform destroy -auto-approve
```

### 问题3：NAT Gateway 删除缓慢

**现象：**
NAT Gateway 删除需要很长时间（1-2分钟）

**解决方案：**
这是正常现象，耐心等待。可以在另一个终端监控：

```bash
# 监控 NAT Gateway 状态
watch -n 10 "aws ec2 describe-nat-gateways --region us-west-2 --query 'NatGateways[?contains(Tags[?Key==\`Name\`].Value, \`my-project\`)].{Name:Tags[?Key==\`Name\`].Value|[0],State:State,NatGatewayId:NatGatewayId}' --output table"
```

### 问题4：EBS 卷删除失败

**错误信息：**
```
Error: VolumeInUse: Volume vol-xxx is currently attached to i-xxx
```

**解决方案：**
```bash
# 1. 删除使用 EBS 卷的 Pod
kubectl delete namespace ebs-test

# 2. 等待卷分离
sleep 30

# 3. 继续销毁
terraform destroy -auto-approve
```

## 🛠️ 预防措施

### 1. 使用改进的配置

确保使用了以下改进：

- ✅ Helm release 配置了 `cleanup_on_fail = true`
- ✅ 添加了适当的 `depends_on` 关系
- ✅ Provider 配置了错误处理
- ✅ 使用了 `null_resource` 进行清理

### 2. 销毁前检查清单

在运行 `terraform destroy` 之前：

- [ ] 删除所有测试 namespace
- [ ] 确认没有运行中的 LoadBalancer 服务
- [ ] 确认没有活跃的 Ingress 资源
- [ ] 检查是否有手动创建的 AWS 资源

### 3. 安全销毁流程

```bash
# 1. 运行预清理脚本
./scripts/pre-destroy-cleanup.sh

# 2. 检查计划
terraform plan -destroy

# 3. 执行销毁
terraform destroy -auto-approve

# 4. 验证清理完成
aws ec2 describe-vpcs --region us-west-2 --filters "Name=tag:Name,Values=my-project-vpc"
```

## 🚨 紧急情况处理

### 如果 Terraform 状态损坏

```bash
# 1. 备份状态文件
cp terraform.tfstate terraform.tfstate.backup

# 2. 手动清理 AWS 资源
aws eks delete-cluster --name my-project-eks-cluster --region us-west-2
aws ec2 delete-vpc --vpc-id vpc-xxxxxxxxx --region us-west-2

# 3. 清理状态文件
terraform state list
terraform state rm <resource_name>
```

### 如果部分资源无法删除

```bash
# 使用 AWS CLI 强制删除
aws elbv2 delete-load-balancer --load-balancer-arn <arn> --region us-west-2
aws ec2 delete-security-group --group-id sg-xxxxxxxxx --region us-west-2
```

## 📞 获取帮助

如果遇到其他问题：

1. 检查 Terraform 日志：`TF_LOG=DEBUG terraform destroy`
2. 检查 AWS CloudTrail 事件
3. 查看 EKS 集群日志
4. 联系 AWS 支持（如果是 AWS 服务问题）

## 🔄 重新部署

销毁完成后，如需重新部署：

```bash
# 1. 清理本地状态
rm -rf .terraform .terraform.lock.hcl terraform.tfstate*

# 2. 重新初始化
terraform init

# 3. 重新部署
terraform apply -auto-approve
```
