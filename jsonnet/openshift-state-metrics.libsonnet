function(params) {
  local cfg = params,
  local osm = (import 'github.com/openshift/openshift-state-metrics/jsonnet/openshift-state-metrics.libsonnet') + {
    _config+:: {
      namespace: cfg.namespace,
      versions: {
        openshiftStateMetrics: 'latest',
        kubeRbacProxy: 'latest',
      },
      openshiftStateMetrics+:: {
        baseMemory: '32Mi',
      },
    },
  },

  // Remapping everything as this is the only way I could think of without refactoring imported library
  // This shouldn't make much difference as openshift-state-metrics project is scheduled for deprecation
  clusterRoleBinding: osm.openshiftStateMetrics.clusterRoleBinding,
  clusterRole: osm.openshiftStateMetrics.clusterRole,
  deployment: osm.openshiftStateMetrics.deployment {
    metadata+: {
      labels+: {
        'app.kubernetes.io/managed-by': 'cluster-monitoring-operator',
        'app.kubernetes.io/name': 'openshift-state-metrics',
        'app.kubernetes.io/component': 'exporter',
        'app.kubernetes.io/part-of': 'openshift-monitoring',
      },
    },
    spec+: {
      template+: {
        spec+: {
          containers:
            std.map(
              function(c)
                if c.name == 'kube-rbac-proxy-main' || c.name == 'kube-rbac-proxy-self' then
                  c {
                    image: cfg.kubeRbacProxyImage,
                  }
                else
                  c,
              super.containers,
            ),
        },
      },
    },
  },
  serviceAccount: osm.openshiftStateMetrics.serviceAccount,
  service: osm.openshiftStateMetrics.service,
  serviceMonitor: osm.openshiftStateMetrics.serviceMonitor,

}
