# Reliability-Aware Multimodal Industrial Anomaly Detection under Compound Sensor Failures

Industrial anomaly detection systems increasingly rely on multiple sensing modalities such as RGB images and 3D measurements. While recent methods demonstrate strong performance under clean sensing conditions, real-world industrial environments often suffer from sensor degradations including blur, glare, missing depth, point-cloud sparsity, and cross-modal misalignment. These failures frequently occur simultaneously and may locally resemble genuine product defects, leading to unreliable anomaly predictions.

This project investigates a more realistic setting: multimodal industrial anomaly detection under local and compound sensor failures. We aim to develop models that can estimate spatially varying sensor reliability, distinguish product defects from sensing artifacts, and abstain from making confident predictions when the available evidence is insufficient.

The project focuses on three key challenges:

* **Local Reliability Estimation:** determining which regions of each modality remain trustworthy under sensor degradation.
* **Defect–Artifact Disentanglement:** separating true product anomalies from sensor-induced artifacts.
* **Selective Prediction:** providing calibrated confidence estimates and rejecting unreliable predictions when necessary.

Experiments are conducted on MVTec 3D-AD, Real-IAD D³, and Eyecandies under both clean and compound-corruption scenarios.

**Keywords:** Industrial Anomaly Detection, Multimodal Learning, RGB–3D Fusion, Sensor Reliability, Robust Perception, Defect Localization, Selective Prediction.

# Dataset Benchmark
MVTec 3D-AD; Eyecandies; Real-IAD D³ (Draft)
