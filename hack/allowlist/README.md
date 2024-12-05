# Create bundle.xml out of template from codex-processes-ap1




k scale deploy crr-bpe  --replicas=0
k scale deploy crr-fhir --replicas=0
k scale deploy diz-bpe  --replicas=0
k scale deploy diz-fhir --replicas=0
k scale deploy nth-bpe  --replicas=0
k scale deploy nth-fhir --replicas=0


k delete cluster develop-crrbpe-postgres
k delete cluster develop-crrfhir-postgres
k delete cluster develop-dizbpe-postgres
k delete cluster develop-dizfhir-postgres
k delete cluster develop-nthbpe-postgres
k delete cluster develop-nthfhir-postgres
