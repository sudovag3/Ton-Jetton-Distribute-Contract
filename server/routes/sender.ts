import {Router} from "express";
import {distributeHandler, distributeJettonHandler} from "../handlers/sender";
import {validateData} from "../middleware/validation.middleware";
import {DistributeJettonSchema, DistributeSchema} from "../schemas/DistributeSchema"

const router = Router()

/**
 * @swagger
 * /ditribute-ton:
 *  post:
 *    description: ditribute ton
 *    tags: [Distribute]
 *    produces:
 *      - application/json
 *    requestBody:
 *      required: true
 *      content:
 *        application/json:
 *           schema:
 *              $ref: '#/definitions/distribute'
 *    responses:
 *      400:
 *        Description: 'Validation Error'
 *      500:
 *        Description: 'Server Error'
 *      201:
 *        Description: 'Ton distributed successfully'
 */
router.post('/ditribute-ton', validateData(DistributeSchema), distributeHandler);

/**
 * @swagger
 * /ditribute-jetton:
 *  post:
 *    description: Distribute Jettons
 *    tags: [Distribute]
 *    produces:
 *      - application/json
 *    requestBody:
 *      required: true
 *      content:
 *        application/json:
 *           schema:
 *              $ref: '#/definitions/distributeJetton'
 *    responses:
 *      400:
 *        Description: 'Validation Error'
 *      500:
 *        Description: 'Server Error'
 *      201:
 *        Description: 'Jettons distributed successfully'
 */
router.post('/ditribute-jetton', validateData(DistributeJettonSchema), distributeJettonHandler)


export default router