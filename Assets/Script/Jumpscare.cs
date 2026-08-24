using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class JumpScare : MonoBehaviour
{
    [SerializeField] private RawImage scareImage;
    [SerializeField] private AudioSource scareSound;
    [SerializeField] private float displayDuration = 0.5f;

    private bool hasTriggered = false;

    private void OnTriggerEnter(Collider collision)
    {
        if (collision.CompareTag("Player") && !hasTriggered)
        {
            hasTriggered = true;
            TriggerJumpScare();
        }
    }

    // Test bằng phím Space
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            TriggerJumpScare();
        }
    }

    public void TriggerJumpScare()
    {
        StartCoroutine(JumpScareSequence());
    }

    private IEnumerator JumpScareSequence()
    {
        // Bật image
        scareImage.gameObject.SetActive(true);

        // Phát âm thanh
        if (scareSound != null)
        {
            scareSound.Play();
        }

        // Giữ trong khoảng thời gian
        yield return new WaitForSeconds(displayDuration);

        // Tắt image
        scareImage.gameObject.SetActive(false);
    }
}