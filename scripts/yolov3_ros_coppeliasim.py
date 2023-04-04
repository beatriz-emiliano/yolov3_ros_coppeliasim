import sys
import copy
import rospy
import numpy as np
import geometry_msgs.msg
import sim
from sensor_msgs.msg import Image
from math import pi,atan2,degrees,radians
from cv_bridge import CvBridge, CvBridgeError
import time
import cv2 
from csv import DictWriter
from include.coppeliasim import CoppeliaSim, CoppeliaArmRobot, CoppeliaSensor

# Initialize the CoppeliaSim connection
mSim = CoppeliaSim()
clientID = sim.simxStart('127.0.0.1', 19999, True, True, 5000, 5)


if mSim.connect(19999) != -1:
    # If the connection is success, initialize the robot properties
    camera = CoppeliaSensor("/sphericalVisionRGBAndDepth/sphericalVisionRGBAndDepth_sensorRGB", 0)
    camera2 = CoppeliaSensor("/sphericalVisionRGBAndDepth/sphericalVisionRGBAndDepth_sensorDepth", 0)
    # camera = CoppeliaSensor("/kinect/body/rgb", 0) #SCENE - kinect-yolo
    # camera2 = CoppeliaSensor("/kinect/body/depth", 0) #SCENE - kinect-yolo
    
    time.sleep(1)
    camera2 = CoppeliaSensor("/sphericalVisionRGBAndDepth/sphericalVisionRGBAndDepth_sensorDepth", 0)
    
    res, simImage = camera.getImage()
    res2, simImage2 = camera2.getImage()

    # Print camera resolution
    print("Resolution = ", res)

    # Convert image coppeliasim format to opencv format
    img = np.array(simImage, dtype=np.uint8)
    img2 = np.array(simImage2, dtype=np.uint8)
    img.resize([res[1], res[0], 3])
    img2.resize([res2[1], res2[0], 3])
    img_rgb = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
    img_rgb = cv2.flip(img_rgb, 0)
    img_depth = cv2.cvtColor(img2, cv2.COLOR_RGB2BGR)
    img_depth = cv2.flip(img_depth, 0)


    with open('/home/smart/yolov3_ros_coppeliasim/yoloDados/YoloNames.names') as f:
        # cria uma lista com todos os nomes
        labels = [line.strip() for line in f]

    # carrega os arquivos treinados pelo framework
    network = cv2.dnn.readNetFromDarknet('/home/smart/yolov3_ros_coppeliasim/yoloDados/yolov3.cfg',
                                     '/home/smart/yolov3_ros_coppeliasim/yoloDados/yolov3.weights')


    layers_names_all = network.getLayerNames()
    layers_names_output = \
        [layers_names_all[i - 1] for i in network.getUnconnectedOutLayers()]

    probability_minimum = 0.5
    threshold = 0.3

    colours = np.random.randint(0, 255, size=(len(labels), 3), dtype='uint8')

    with open('teste.csv', 'w') as arquivo:
        cabecalho = ['Detectado', 'Acuracia']
        escritor_csv = DictWriter(arquivo, fieldnames=cabecalho)
        escritor_csv.writeheader()
        while True:
            # Captura da camera frame por frame
            _, simImage = camera.getImage()
            _, simImage2 = camera2.getImage() 

            img = np.array(simImage, dtype=np.uint8)
            img2 = np.array(simImage2, dtype=np.uint8)
            img.resize([res[1], res[0], 3])
            img2.resize([res2[1], res2[0], 3])
            img_rgb = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
            img_rgb = cv2.flip(img_rgb, 0)
            img_depth = cv2.cvtColor(img2, cv2.COLOR_RGB2BGR)
            img_depth = cv2.flip(img_depth, 0)

            # pos = list([0,0])
            # size= list([0,0])

            # depthMap=sim.simxGetVisionSensorDepthBuffer(clientID,camera,1,pos,list(size=[0,0]))
            # depthMap=sim.simxUnpackFloats(depthMap)
            # print(depthMap)

            h, w = None, None
            #h2, w2 = None, None

            if w is None or h is None:
                # Fatiar apenas dois primeiros elementos da tupla
                h, w = img_rgb.shape[:2]
                #h2, w2 = img_depth.shape[:2]

            # A forma resultante possui número de quadros, número de canais, largura e altura
            # E.G.:
            blob = cv2.dnn.blobFromImage(img_rgb, 1 / 255.0, (416, 416),
                                        swapRB=True, crop=False)

            # Implementando o passe direto com nosso blob e somente através das camadas de saída
            # Cálculo ao mesmo tempo, tempo necessário para o encaminhamento
            network.setInput(blob)  # definindo blob como entrada para a rede
            start = time.time()
            output_from_network = network.forward(layers_names_output)
            end = time.time()

            # Mostrando tempo gasto para um único quadro atual
            print('Tempo gasto atual {:.5f} segundos'.format(end - start))

            # Preparando listas para caixas delimitadoras detectadas,

            bounding_boxes = []
            bounding_boxes *= 0
            confidences = []
            class_numbers = []

            # Passando por todas as camadas de saída após o avanço da alimentação
            # Fase de detecção dos objetos
            for result in output_from_network:
                for detected_objects in result:
                    scores = detected_objects[5:]
                    class_current = np.argmax(scores)
                    confidence_current = scores[class_current]

                    # Eliminando previsões fracas com probabilidade mínima
                    if confidence_current > probability_minimum:
                        box_current = detected_objects[0:4] * np.array([w, h, w, h])
                        x_center, y_center, box_width, box_height = box_current
                        x_min = int(x_center - (box_width / 2))
                        y_min = int(y_center - (box_height / 2))

                        # Adicionando resultados em listas preparadas
                        bounding_boxes.append([x_min, y_min,
                                            int(box_width), int(box_height)])

                        confidences.append(float(confidence_current))
                        class_numbers.append(class_current)
                        

            results = cv2.dnn.NMSBoxes(bounding_boxes, confidences,
                                    probability_minimum, threshold)

            # Verificando se existe pelo menos um objeto detectado

            if len(results) > 0:
                for i in results.flatten():
                    x_min, y_min = bounding_boxes[i][0], bounding_boxes[i][1]
                    box_width, box_height = bounding_boxes[i][2], bounding_boxes[i][3]
                    bounding_boxes_in = [x_min, y_min, box_width, box_height]
                    colour_box_current = colours[class_numbers[i]].tolist()
                    cv2.rectangle(img_rgb, (x_min, y_min),
                                (x_min + box_width, y_min + box_height),
                                colour_box_current, 2)

                    # Preparando texto com rótulo e acuracia para o objeto detectado
                    text_box_current = '{}: {:.4f}'.format(labels[int(class_numbers[i])],
                                                        confidences[i])

                    # Coloca o texto nos objetos detectados
                    cv2.putText(img_rgb, text_box_current, (x_min, y_min - 5),
                                cv2.FONT_HERSHEY_SIMPLEX, 3, colour_box_current, 3)
                    
                    #cv2.putText(img_depth, text_box_current, (x_min, y_min - 5),
                                #cv2.FONT_HERSHEY_SIMPLEX, 3, colour_box_current, 3)
    

                    escritor_csv.writerow(
                        {"Detectado": text_box_current.split(':')[0], "Acuracia": text_box_current.split(':')[1]})

                    print(text_box_current.split(':')[0] + " - " + text_box_current.split(':')[1] + " - " + str(bounding_boxes_in))


            cv2.namedWindow('YOLO v3 -RGB- CoppeliaSim', cv2.WINDOW_NORMAL)
            cv2.imshow('YOLO v3 -RGB- CoppeliaSim', img_rgb)
            cv2.namedWindow('YOLO v3 -Depth- CoppeliaSim', cv2.WINDOW_NORMAL)
            cv2.imshow('YOLO v3 -Depth- CoppeliaSim', img_depth)
            

            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

    # Show image
    #cv2.imshow("Vision Sensor", img2)
    #cv2.waitKey(0)
else:
    print("ERROR: CoppeliaSim connection failed!!!")
