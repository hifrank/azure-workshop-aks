# azure-workshop-aks
This is quick start workshop material for aks storage.
As for now(2022/9/15), AKS natively support below CSI storage drivers:
1. Azure Disk
2. Azure Files
3. Azure Blob storage

you may refer [here](https://docs.microsoft.com/en-us/azure/aks/csi-storage-drivers) for Detail

Here, we are going to have quick start guide for Azure Disk and Azure files with AKS.

## Azure Disk

### Storage Class

Along with AKS, there are 2 storage classes using Azure Disk:
1. managed-csi: Use standard SSD locally redundant storage(LRS) to create a managed disk.
2. managed-csi-premium: Use Azure Premium LRS to create a managed disk.

to check these storage class detail, you can use kubectl get sc <storage class>, below are example output
```bash
$ kubectl get sc managed-csi -o yaml

allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  creationTimestamp: "2022-08-26T08:17:03Z"
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
    kubernetes.io/cluster-service: "true"
  name: managed-csi
  resourceVersion: "413"
  uid: 44276e82-4174-46ca-9845-e49befb247a1
parameters:
  skuname: StandardSSD_LRS
provisioner: disk.csi.azure.com
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```
In some case, you might want to create your own storage class with specific parameter which is not covered by default storage class, for ex, you want to assign tags to the provisioned managed disk, or change resource group of the disk. You may refer to [here](https://docs.microsoft.com/en-us/azure/aks/azure-disk-csi#storage-class-driver-dynamic-disks-parameters) for more information about parameter you can use.

Right here, we create a Storage Class which will be assigned for some predefined tags:

#### 1. Create storage class

```bash
$ kubectl apply -f ./disk/storage_class_demo.yaml
```
```bash
 --output--
storageclass.storage.k8s.io/azuredisk-csi-demo created
```

#### 2. Check the storage class exist

```
$ kubectl get sc azuredisk-csi-demo -o yaml
```
```yaml
 --output--
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"allowVolumeExpansion":true,"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"azuredisk-csi-demo"},"parameters":{"skuname":"StandardSSD_LRS","tags":"env=demo,costceneter=demo"},"provisioner":"disk.csi.azure.com","reclaimPolicy":"Delete","volumeBindingMode":"WaitForFirstConsumer"}
  creationTimestamp: "2022-09-15T14:57:35Z"
  name: azuredisk-csi-demo
  resourceVersion: "6467041"
  uid: d3db4d1a-d3ea-4cbc-86cd-8aee8c82d91c
parameters:
  skuname: StandardSSD_LRS
  tags: env=demo,costceneter=demo
provisioner: disk.csi.azure.com
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
  
```
### Dynamically create a Azure Disk PC using storage class we just created and mount to a pod

```bash
kubectl apply -f ./disk/pod_nginx_demo.yaml
```
```bash
--output--
persistentvolumeclaim/pvc-azuredisk-demo created
pod/nginx-azuredisk created
```
Then we can check the result by:
```bash
# check the PV exist
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                        STORAGECLASS         REASON   AGE
pvc-86bdc20f-e078-4538-851d-50e1eaf882bc   5Gi        RWO            Delete           Bound    default/pvc-azuredisk-demo   azuredisk-csi-demo            55s

# check the disk is mounted to the running pod
$ kubectl exec -it nginx-azuredisk -- sh
> tail -n 2 /mnt/azuredisk/outfile
Thu Sep 15 15:23:50 UTC 2022
Thu Sep 15 15:23:51 UTC 2022

# check tag assigned to azure managed disk, first get the disk name & resource group
$ kubectl get pv -o yaml
```
```yaml
apiVersion: v1
items:
- apiVersion: v1
  kind: PersistentVolume
  metadata:
  ...
  spec:
  ...
    csi:
      driver: disk.csi.azure.com
      volumeAttributes:
        volumeHandle: /subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.Compute/disks/<disk name>
```
```bash
# then you can use azure portl to check managed disk tags, or use azure cli like below:
$ az disk show --name <disk name> --resource-group <resource group name> --query tags
{
  "costceneter": "demo",
  "env": "demo",
  "k8s-azure-created-by": "kubernetes-azure-dd",
  "kubernetes.io-created-for-pv-name": "<your disk anme>",
  "kubernetes.io-created-for-pvc-name": "pvc-azuredisk-demo",
  "kubernetes.io-created-for-pvc-namespace": "default"
}
```
Now you just created a managed disk with tags you specify and mounted to your pod.

You can clean up the resouce by:
```bash
kubectl delete -f disk/pod_nginx_demo.yaml
kubectl delete -f ./disk/storage_class_demo.yaml
```
To learn more, make you sure check the [azure document for azure disk](https://docs.microsoft.com/en-us/azure/aks/azure-disk-csi).


## Azure File

### Storage Class

Along with AKS, there are 2 storage classes using Azure Disk:
1. azurefile-csi: Uses Azure Standard Storage to create an Azure Files share.
2. azurefile-csi-premium: Uses Azure Premium Storage to create an Azure Files share.

Here, like Azure Disk, we are going to create custom Azure file storage class for demo.
#### 1. Create storage class

```bash
$ kubectl apply -f ./file/storage_class_file_demo.yaml 

 --output--
storageclass.storage.k8s.io/azurefile-csi-demo created

```
Azure file need a storage account, in this demo, we don't specifiy stoage account for it, so it will create one for us. (If you need to specify stoage account, make sure it's existed one.)
#### 2. Check the storage class exist
```bash
# The minium stoage size of Azure File is 100G.
$ kubectl get sc azurefile-csi-demo

--output--
NAME                 PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
azurefile-csi-demo   file.csi.azure.com   Delete          Immediate           true                   9m59s
```

### Dynamically create a Azure File using storage class we just created and mount to a pod
First we create a PVC and a nginx pod to mount the PV.
```bash
$kubectl apply -f ./file/pod_nginx_file_demo.yaml

--output--
persistentvolumeclaim/pvc-azurefile-demo created
pod/nginx-azurefile created
```

Then we can check the PVC status, it should looked like
```
$ kubectl get pvc

--output--
NAME                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS         AGE
pvc-azurefile-demo   Bound    pvc-c346351e-4f1f-4390-903b-a6fde185ca14   100Gi      RWO            azurefile-csi-demo   16m
```

We can check how it looked in the pod, you should able to get a disk mounted in path /mnt/azuredisk with size 100G.
```bash
$ kubectl exec -it nginx-azurefile -- sh
> tail -n 2 /mnt/azuredisk/outfile

--output--
Thu Sep 15 16:12:09 UTC 2022
Thu Sep 15 16:12:10 UTC 2022

> df -h |grep /azuredisk

--output--
                        100.0G     64.0K    100.0G   0% /mnt/azuredisk
```

To remove the resource
```bash
kubectl delete -f ./file/pod_nginx_file_demo.yaml 
# note this will only remove azure file share in storage account, but the storage account won't be delete, you may have to remove it manually.
kubectl delete -f ./file/storage_class_file_demo.yaml

```

Now we just create a stoage class, pvc and pv, mounted to a running nginx pod.

Make sure you read this for more detal about [azure file](https://docs.microsoft.com/en-us/azure/aks/azure-files-csi).
