using UnityEngine;

public class VHSEffect : MonoBehaviour
{
    public Material vhsMaterial;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (vhsMaterial != null)
        {
            Graphics.Blit(source, destination, vhsMaterial);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}