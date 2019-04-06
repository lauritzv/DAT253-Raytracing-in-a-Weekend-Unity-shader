//
//  based upon https://wiki.unity3d.com/index.php/MouseOrbitZoom

//  Retrieved from "http://wiki.unity3d.com/index.php?title=MouseOrbitZoom&oldid=13023"
//  original: http://www.unifycommunity.com/wiki/index.php?title=MouseOrbitZoom
//
using UnityEngine;
using System.Collections;

[AddComponentMenu("Camera-Control/3dsMax Camera Style")]
public class maxCamera : MonoBehaviour
{
    public Transform target;
    public Vector3 targetOffset;
    public float distance = 5.0f;
    public float maxDistance = 20;
    public float minDistance = .6f;
    public float xSpeed = 200.0f;
    public float ySpeed = 200.0f;
    public int yMinLimit = -80;
    public int yMaxLimit = 80;
    public int zoomRate = 40;
    public float panSpeed = 0.3f;
    public float zoomDampening = 5.0f;

    private float xDeg = 0.0f;
    private float yDeg = 0.0f;
    private float currentDistance;
    private float desiredDistance;
    private Quaternion currentRotation;
    private Quaternion desiredRotation;
    private Quaternion rotation;
    private Vector3 position;

    private Vector3 _origPosition, _origTargetPosition;
    private Quaternion _origRotation;
    private float _origXDeg, _origYDeg;

    public Material material;

    void Start() { Init(); }
    void OnEnable() { Init(); }

    public void Init()
    {
        distance = Vector3.Distance(transform.position, target.position);
        currentDistance = distance;
        desiredDistance = distance;

        //be sure to grab the current rotations as starting points.
        position = transform.position;
        rotation = transform.rotation;
        currentRotation = transform.rotation;
        desiredRotation = transform.rotation;

        xDeg = Vector3.Angle(Vector3.right, transform.right);
        yDeg = Vector3.Angle(Vector3.up, transform.up);

        // Record original values for resetting
        _origPosition = position;
        _origRotation = rotation;
        _origTargetPosition = target.position;
        _origXDeg = xDeg;
        _origYDeg = yDeg;
    }

    /*
     * Camera logic on LateUpdate to only update after all character movement logic has been handled.
     */
    void LateUpdate()
    {
        if (Input.GetKeyDown(KeyCode.R))
        {
            ResetCameraPosition();
        }

        else if (Input.GetMouseButton(1))
            RightMousePressed();

        ////////Orbit Position

        // affect the desired Zoom distance if we roll the scrollwheel
        desiredDistance -= Input.GetAxis("Mouse ScrollWheel") * Time.deltaTime * zoomRate * Mathf.Abs(desiredDistance);
        //clamp the zoom min/max
        desiredDistance = Mathf.Clamp(desiredDistance, minDistance, maxDistance);
        // For smoothing of the zoom, lerp distance
        currentDistance = Mathf.Lerp(currentDistance, desiredDistance, Time.deltaTime * zoomDampening);

        // calculate position based on the new currentDistance
        position = target.position - (rotation * Vector3.forward * currentDistance + targetOffset);
        transform.position = position;

        UpdateMaterial();
    }

    private void RightMousePressed()
    {
        // If Control and Alt and Right button? ZOOM!
        if (Input.GetKey(KeyCode.LeftAlt) && Input.GetKey(KeyCode.LeftControl))
        {
            desiredDistance -= Input.GetAxis("Mouse Y") * Time.deltaTime * zoomRate * 0.125f * Mathf.Abs(desiredDistance);
        }
        // If right mouse and left alt are selected? ORBIT
        else if (Input.GetKey(KeyCode.LeftAlt))
        {
            xDeg += Input.GetAxis("Mouse X") * xSpeed * 0.02f;
            yDeg -= Input.GetAxis("Mouse Y") * ySpeed * 0.02f;

            ////////OrbitAngle

            //Clamp the vertical axis for the orbit
            yDeg = ClampAngle(yDeg, yMinLimit, yMaxLimit);
            // set camera rotation
            desiredRotation = Quaternion.Euler(yDeg, xDeg, 0);
            currentRotation = transform.rotation;

            rotation = Quaternion.Lerp(currentRotation, desiredRotation, Time.deltaTime * zoomDampening);
            transform.rotation = rotation;
        }
        // otherwise if right mouse is selected, we pan by way of transforming the target in screenspace
        else
        {
            //grab the rotation of the camera so we can move in a psuedo local XY space
            target.rotation = transform.rotation;
            target.Translate(Vector3.right * -Input.GetAxis("Mouse X") * panSpeed);
            target.Translate(transform.up * -Input.GetAxis("Mouse Y") * panSpeed, Space.World);
        }
    }

    private void ResetCameraPosition()
    {
        //Positions
        position = _origPosition;
        target.position = _origTargetPosition;
        transform.position = _origPosition;

        //Rotations
        rotation = _origRotation;
        xDeg = _origXDeg;
        yDeg = ClampAngle(_origYDeg, yMinLimit, yMaxLimit);
        currentRotation = rotation;
        transform.rotation = _origRotation;
        desiredRotation = currentRotation;

        // Distances
        distance = Vector3.Distance(transform.position, target.position);
        currentDistance = distance;
        desiredDistance = currentDistance;

        RightMousePressed();
    }

    private void UpdateMaterial()
    {
        material.SetVector("_CameraPosition", new Vector4(transform.position.x, transform.position.y, transform.position.z, 0f));
        material.SetVector("_CameraTarget", new Vector4(target.position.x, target.position.y, target.position.z, 0f));
        material.SetVector("_CameraUp", new Vector4(transform.up.x, transform.up.y, transform.up.z, 0f));
    }

    private static float ClampAngle(float angle, float min, float max)
    {
        if (angle < -360)
            angle += 360;
        if (angle > 360)
            angle -= 360;
        return Mathf.Clamp(angle, min, max);
    }
}