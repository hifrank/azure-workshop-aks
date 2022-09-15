# azure-workshop-aks
This is quick start workshop material for aks storage.
As for now(2022/9/15), AKS natively support below CSI storage drivers:
1. Azure Disk
2. Azure Files
3. Azure Blob storage

you may refer [here](https://docs.microsoft.com/en-us/azure/aks/csi-storage-drivers) for Detail

Here, we are going to have quick start guide for Azure Disk and Azure files with AKS.

## Azure file

### Storage Class
Along with AKS, there are 2 storage classes using Azure Disk:
1. managed-csi: Use standard SSD locally redundant storage(LRS) to create a managed disk.
2. managed-csi-premium: Use Azure Premium LRS to create a managed disk.

to check these storage class detail, you can use kubectl get sc <storage class>, below are example output
 ```
 > kubectl get sc managed-csi -o yaml

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

Right here, we create a Storage Class which will be assigned for some predefined tags.
  ```
  kubectl apply -f ./file/storage_class_demo.yaml
  ```

