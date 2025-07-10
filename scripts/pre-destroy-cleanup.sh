#!/bin/bash

# Pre-destroy cleanup script for EKS infrastructure
# This script should be run before 'terraform destroy' to avoid common issues

set -e

echo "🧹 EKS 基础设施销毁前清理脚本"
echo "=================================="

# 检查必要的工具
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl 未安装"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ helm 未安装"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ aws cli 未安装"; exit 1; }

# 获取集群名称
CLUSTER_NAME=${1:-"my-project-eks-cluster"}
REGION=${2:-"us-west-2"}

echo "📋 清理集群: $CLUSTER_NAME (区域: $REGION)"

# 1. 更新 kubeconfig
echo "🔧 更新 kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME || {
    echo "⚠️  无法连接到集群，可能已被删除"
    exit 0
}

# 2. 删除所有 LoadBalancer 类型的服务
echo "🔧 删除 LoadBalancer 服务..."
kubectl get svc --all-namespaces -o json | \
jq -r '.items[] | select(.spec.type=="LoadBalancer") | "\(.metadata.namespace) \(.metadata.name)"' | \
while read namespace name; do
    if [ ! -z "$namespace" ] && [ ! -z "$name" ]; then
        echo "  删除 LoadBalancer: $namespace/$name"
        kubectl delete svc "$name" -n "$namespace" --ignore-not-found=true --timeout=60s
    fi
done

# 3. 删除所有 Ingress 资源
echo "🔧 删除 Ingress 资源..."
kubectl get ingress --all-namespaces -o json | \
jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' | \
while read namespace name; do
    if [ ! -z "$namespace" ] && [ ! -z "$name" ]; then
        echo "  删除 Ingress: $namespace/$name"
        kubectl delete ingress "$name" -n "$namespace" --ignore-not-found=true --timeout=60s
    fi
done

# 4. 删除 AWS Load Balancer Controller
echo "🔧 删除 AWS Load Balancer Controller..."
helm uninstall aws-load-balancer-controller -n kube-system || {
    echo "⚠️  ALB Controller 已删除或不存在"
}

# 5. 等待 ALB 资源清理
echo "⏳ 等待 AWS 负载均衡器清理..."
sleep 30

# 6. 检查并删除遗留的 ALB
echo "🔧 检查遗留的 ALB..."
aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-`) == `true`].[LoadBalancerArn,LoadBalancerName]' --output table || {
    echo "⚠️  无法列出 ALB，可能权限不足或已清理"
}

# 7. 删除测试命名空间
echo "🔧 删除测试命名空间..."
kubectl delete namespace ebs-test --ignore-not-found=true --timeout=60s

# 8. 清理 Finalizers（如果存在问题）
echo "🔧 检查并清理 Finalizers..."
kubectl get namespace -o json | \
jq -r '.items[] | select(.status.phase=="Terminating") | .metadata.name' | \
while read ns; do
    if [ ! -z "$ns" ]; then
        echo "  清理命名空间 Finalizer: $ns"
        kubectl patch namespace "$ns" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
    fi
done

echo "✅ 清理完成！现在可以安全运行 'terraform destroy'"
echo ""
echo "💡 建议的销毁命令："
echo "   terraform destroy -auto-approve"
echo ""
echo "🚨 如果仍然遇到问题，可以尝试："
echo "   terraform destroy -target=module.eks"
echo "   terraform destroy -target=module.bastion"
echo "   terraform destroy -target=module.vpc"
