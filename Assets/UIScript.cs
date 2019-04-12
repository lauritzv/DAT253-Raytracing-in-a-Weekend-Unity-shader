using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using UnityEngine;
using UnityEngine.UI;

public class UIScript : MonoBehaviour
{
    [SerializeField] private Material material;

    // Text fields that are updated:
    [SerializeField] private Text _aaText, _bouncesText, _sphereHeightText, 
        _sphereHueText, _sphereSatText, _sphereValText, _sphereDielectricToggled, _fuzzText, _iorText, _vfovText;

    [SerializeField] private GameObject _hsvGroup, _iorGroup; // for hiding or showing ui elements

    private float h = 0.0f, s = 0.62f, v = 0.8f; // = RGB(0.8, 0.3, 0.3, 1.0)

    public void OnAASliderChanged(float value)
    {
        material.SetFloat("_aa_samples",value);
        _aaText.text = ((int) value).ToString();
    }

    public void OnBouncesSliderChanged(float value)
    {
        material.SetFloat("MAXIMUM_DEPTH", value);
        _bouncesText.text = ((int) value).ToString();
    }

    public void OnGammaCorrectionChanged(bool value)
    {
        if (value) material.SetFloat("_gammacorrect", 1f);
        else material.SetFloat("_gammacorrect", 0f);
    }
    public void OnSpherePosSliderChanged(float value)
    {
        material.SetFloat("_sphereOneHeight", value);
        _sphereHeightText.text = value.ToString(CultureInfo.InvariantCulture);
    }

    public void OnHueSliderChanged(float value)
    {
        h = value;
        _sphereHueText.text = value.ToString(CultureInfo.InvariantCulture);
        UpdateColor();
    }

    public void OnSatSliderChanged(float value)
    {
        s = value;
        _sphereSatText.text = value.ToString(CultureInfo.InvariantCulture);
        UpdateColor();
    }

    public void OnValSliderChanged(float value)
    {
        v = value;
        _sphereValText.text = value.ToString(CultureInfo.InvariantCulture);
        UpdateColor();
    }

    public void OnFuzzSliderChanged(float value)
    {
        _fuzzText.text = value.ToString(CultureInfo.InvariantCulture);
        material.SetFloat("_sphereTwoFuzz", value);
    }

    public void OnIORSliderChanged(float value)
    {
        _iorText.text = value.ToString(CultureInfo.InvariantCulture);
        material.SetFloat("_sphereOneIor", value);
    }
    public void OnVfovSliderChanged(float value)
    {
        _vfovText.text = value.ToString(CultureInfo.InvariantCulture);
        material.SetFloat("_vfov", value);
    }

    private void UpdateColor()
    {
        Color col = Color.HSVToRGB(h, s, v);
        material.SetVector("_sphereOneColor", new Vector4(col.r, col.g, col.b, 1.0f));
    }

    public void ToggleSphereDielectric(bool value)
    {
        if (value)
        {
            _sphereDielectricToggled.text = "Diffuse";
            material.SetFloat("_sphereOneDielectric", 0f);
        }
        else
        {
            _sphereDielectricToggled.text = "Dielectric";
            material.SetFloat("_sphereOneDielectric", 1f);
        }
        _iorGroup.SetActive(!value);
        _hsvGroup.SetActive(value); // only show color sliders when diffuse
    }
}
