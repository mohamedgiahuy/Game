
using UnityEngine;

public class CameraBob : MonoBehaviour
{
    public CharacterController player;

    [Header("Walking")]
    public float walkFrequency = 8f;
    public float walkAmplitude = 0.02f;

    [Header("Running")]
    public float runFrequency = 12f;
    public float runAmplitude = 0.045f;
    public float runThreshold = 5f;

    [Header("Smoothing")]
    public float smoothSpeed = 8f;

    [Header("Camera Rotation")]
    public float rotationAmount = 0.5f;
    public float rotationSmooth = 5f;

    private Vector3 startPosition;
    private Quaternion startRotation;
    private float timer;
    private float currentRotation;

    void Start()
    {
        startPosition = transform.localPosition;
        startRotation = transform.localRotation;
    }

    void LateUpdate()
    {
        if (player == null) return;

        Vector3 velocity = player.velocity;
        velocity.y = 0f;

        bool moving = velocity.magnitude > 0.1f;
        bool running = velocity.magnitude > runThreshold;

        float targetX = 0f;
        float targetY = 0f;
        float targetRotation = 0f;

        if (moving)
        {
            float frequency = running
                ? runFrequency : walkFrequency;

            float amplitude = running
                ? runAmplitude : walkAmplitude;

            timer += Time.deltaTime * frequency;

            targetY = Mathf.Sin(timer * 2f) * amplitude;
            targetX = Mathf.Cos(timer) * amplitude * 0.5f;

            targetRotation = Mathf.Sin(timer) * rotationAmount;
        }
        else
        {
            timer = 0f;
        }

        Vector3 targetPosition = startPosition
            + new Vector3(targetX, targetY, 0f);

        transform.localPosition = Vector3.Lerp(
            transform.localPosition,
            targetPosition,
            Time.deltaTime * smoothSpeed
        );

        currentRotation = Mathf.Lerp(
            currentRotation,
            targetRotation,
            Time.deltaTime * rotationSmooth
        );

        transform.localRotation = startRotation
            * Quaternion.Euler(0f, 0f, currentRotation);
    }
}
